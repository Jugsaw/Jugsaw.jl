module Server
using HTTP
using JugsawIR.JSON3
import CloudEvents
import DaprClients
using Dates

@enum JobStatusEnum starting processing pending succeeded failed canceled

struct Payload
    args::Any
    kwargs::Any
end

struct Job
    id::String
    created_at::Float64
    created_by::String

    demo::JugsawDemo
    payload::Payload
end

Base.@kwdef struct JobStatus
    id::String
    status::JobStatusEnum
    timestamp::Float64 = datetime2unix(now())
    description::String = ""
end

abstract type AbstractEventService end
Base.@kwdef struct DaprService <: AbstractEventService
    timeout::Float64 = 15.0
    pub_sub::String = "jobs"
    result_store::String = "job-result-store"
end
get_timeout(dapr::DaprService) = dapr.timeout
function publish(dapr::DaprService, job_status::JobStatus)
    return DaprClients.publish_event(dapr.pub_sub, string(job_status.status), job_status; headers=Pair{SubString{String},SubString{String}}["Content-Type"=>"application/json"])
end
function save_state(dapr::DaprService, job::Job, res)
    key = "JUGSAW-JOB-RESULT:$(job.id)"
    return DaprClients.save_state(dapr.result_store, key, JSON3.write(res))
end

############# The mock event service for printing job status and saving results
struct MockEventService <: AbstractEventService
    print_event::Bool
    save_dir::String
end
function MockEventService(; print_event::Bool=true, save_dir::String="")
    return MockEventService(print_event, save_dir)
end
get_timeout(::MockEventService) = 1.0
# update job status to Dapr
function publish(dapr::MockEventService, job_status::JobStatus)
    dapr.print_event && @info "[STATUS] $job_status"
    # log into file
    !isempty(dapr.save_dir) && open(joinpath(dapr.save_dir, job_status.id, "status.log"), "a") do f
        write(f, string(job_status))
    end
    return nothing
end
function save_state(dapr::MockEventService, job::Job, res)
    key = "JUGSAW-JOB-RESULT:$(job.id)"
    dapr.print_event && @info "[$key] $res"
    # save to file
    ir, tt = julia2ir(res)
    !isempty(dapr.save_dir) && open(joinpath(dapr.save_dir, job.id, "result.jug"), "w") do f
        write(f, ir)
    end
    return nothing
end

########################## Application Runtime
struct AppRuntime{ES<:AbstractEventService}
    app::AppSpecification
    channel::Channel{Job}
    dapr::ES
end

function AppRuntime(app::AppSpecification, dapr::AbstractEventService)
    channel = Channel() do ch
        for job in ch
            try
                # res = f(job.payload.args...; job.payload.kwargs...)
                res = fevalself(Call(democall.fname, job.args, job.kwargs))
                save_state(dapr, job, JSON3.write(res))
                publish(dapr, JobStatus(id=job.id, status=succeeded))
            catch ex
                # state_store[msg.response.object_id] = CachedError(e, _error_msg(e))
                st_io = IOBuffer()
                showerror(st_io, CapturedException(ex, catch_backtrace()))
                println(String(take!(st_io)))
                publish(dapr, JobStatus(id=job.id, status=failed, description=string(ex)))
            end
        end
    end
    return AppRuntime(app, channel, dapr)
end

function match_demo_or_throw(adt::JugsawADT, app::AppSpecification)
    if adt.typename != "JugsawIR.Call"
        throw(BadSyntax(adt))
    end
    fname, args, kwargs = adt.fields
    res = _match_demo(fname, args.typename, kwargs.typename, app)
    if res === nothing
        throw(NoDemoException(adt, app))
    end
    return res
end
function _match_demo(fname, args_type, kwargs_type, app::AppSpecification)
    if !haskey(app.method_demos, fname) || isempty(app.method_demos[fname])
        return nothing
    end
    for demo in app.method_demos[fname]
        _, dargs, dkwargs = demo.fcall.fname, demo.meta["args_type"], demo.meta["kwargs_type"]
        if dargs == args_type && dkwargs == kwargs_type
            return demo
        end
    end
    return nothing
end

function addjob!(r::AppRuntime, adt::JugsawADT, thisdemo::Call)
    # find a demo
    fname, args, kwargs = adt.fields
    # IF tree is a function call, return an `object_id` for return value.
    #     recurse over args and kwargs to get `Call` parsed.
    req = Call(thisdemo.fname,
        ntuple(i->renderobj!(r, args.fields[i], thisdemo.args[i]), length(args.fields)),
        typeof(thisdemo.kwargs)(ntuple(i->renderobj!(r, kwargs.fields[i], thisdemo.kwargs[i]), length(kwargs.fields)))
    )
    # add task to the queue
    @info "task added to the queue: $req"
    resp = ObjectRef()
    r.state_store[resp.object_id] = Future()
    # TODO: load actor state from state store
    a = activate(r, adt)
    put_message(a, Message(req, resp))

    # Return a `ObjectRef` instance.
    return resp
end

# if adt is a function call, launch a job and return an object getter, else, return an object.
function renderobj!(r::AppRuntime, adt, thisdemo)
    if adt isa JugsawADT && hasproperty(adt, :typename) && adt.typename == "JugsawIR.Call"
        fdemo = match_demo_or_throw(adt, r.app)
        resp = addjob!(r, adt, fdemo.fcall)
        # Return an object getter, which is a `Call` instance that fetches objects from the state_store.
        return object_getter(r.state_store, resp.object_id)
    else
        return JugsawIR.adt2julia(adt, thisdemo)
    end
end

# an object getter to load return values of a function call from the state store
function object_getter(state_store::StateStore, object_id::String)
    function getter(s::StateStore, id::String)
        res = s[id]
        # rethrow a cached error
        res isa CachedError && Base.rethrow(res.exception)
        return res
    end
    Call(getter, (state_store, object_id), (;))
end


function job_handler(r::AppRuntime, req::HTTP.Request)
    println(req.headers)
    println(req.body)
    evt = from_http(req.headers, req.body)
    # CloudEvent
    # (:id, :source, :specversion, :type, :datacontenttype, :dataschema, :subject, :time, :extensions, :data)
    adt = JugsawIR.ir2adt(String(evt.data))
    @info "got job adt: $adt"

    # if !haskey(runtime.app.method_demos, obj.func) || !haskey(runtime.app.method_demos[obj.func], obj.signature)
    #     publish(runtime.dapr, JobStatus(id=job.id, status=failed, description="$(job.func) with signature $(obj.signature) is not registered!"))
    # end

    # top level must be a function call
    # add jobs recursively to the queue
    try
        thisdemo = match_demo_or_throw(adt, r.app).fcall
        addjob!(r, adt, thisdemo)
        # return HTTP.Response(200, ["Content-Type" => "application/json"], JSON3.write(resp))
        return HTTP.Response(200, "Job submitted!")
    catch e
        @info e
        return _error_response(e)
    end
    # demo = runtime.app.method_demos[obj.func][obj.signature]
    # job = Job(obj.id, obj.created_at, obj.created_by, demo, obj.payload)
    # println(job)
    # submit_job(runtime, job)
end

function submit_job(runtime::AppRuntime, job::Job)
    res = timedwait(get_timeout(runtime.dapr)) do
        put!(runtime.channel, job)
        publish(runtime.dapr, JobStatus(id=job.id, status=processing))
        true
    end
    res || publish(runtime.dapr, JobStatus(id=job.id, status=pending, description="Failed to submit job after $TIME_OUT seconds."))
end

function get_router(runtime::AppRuntime)
    r = HTTP.Router()

    HTTP.register!(r, "GET", "/healthz", _ -> JSON3.write((; status="OK")))
    HTTP.register!(r, "POST", "/events/jobs", req->job_handler(runtime, req))
    HTTP.register!(r, "GET", "/dapr/subscribe",
        _ -> JSON3.write([(pubsubname="jobs", topic="$(runtime.app.created_by).$(runtime.app.name).$(rumtime.app.ver)", route="/events/jobs")])
    )
    return r
end

function serve(runtime::AppRuntime, is_async::Bool=false, port::Int=8088)
    # release demo
    # dir === nothing || save_demos(dir, runtime.app)
    r = get_router(runtime)
    if is_async
        @async HTTP.serve(r, "0.0.0.0", port)
    else
        HTTP.serve(r, "0.0.0.0", port)
    end
end

#####
# # TODO: use register instead
# greet(x::String="World") = "Hello, $(x)!"
# greet(x::JSON3.Object) = "(JSON) Hello, $(x.name)!"


# runtime = AppRuntime()
# dapr = MockEventService(".jugsaw_workspace")
# register!(runtime, dapr, "greet", greet)

end