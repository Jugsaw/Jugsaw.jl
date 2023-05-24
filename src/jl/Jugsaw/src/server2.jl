module Server
using HTTP
using JugsawIR
using Dates: now, datetime2unix
using JugsawIR.JSON3
import CloudEvents
import DaprClients
import ..AppSpecification

export Job, JobStatus
export MockEventService, publish_status, fetch_status, save_state, load_state, get_timeout
export AppRuntime, addjob!

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
function publish_status(dapr::DaprService, job_status::JobStatus)
    return DaprClients.publish_event(dapr.pub_sub, string(job_status.status), job_status; headers=Pair{SubString{String},SubString{String}}["Content-Type"=>"application/json"])
end
function fetch_status(dapr::DaprService, job_id::String; timeout)
    error("@")
end
function save_state(dapr::DaprService, job_id::AbstractString, res)
    key = "JUGSAW-JOB-RESULT:$(job_id)"
    return DaprClients.save_state(dapr.result_store, key, JSON3.write(res))
end
function load_state(dapr::DaprService, job_id::AbstractString, resdemo; timeout::Real)
    error("@")
end

############# The mock event service for printing job status and saving results
struct MockEventService <: AbstractEventService
    print_event::Bool
    save_dir::String
end
function MockEventService(save_dir::String; print_event::Bool=true)
    return MockEventService(print_event, save_dir)
end
get_timeout(::MockEventService) = 1.0
# update job status to Dapr
function publish_status(dapr::MockEventService, job_status::JobStatus)
    dapr.print_event && @info "[PUBLISH STATUS] $job_status"
    # log into file
    dir = joinpath(dapr.save_dir, job_status.id)
    mkpath(dir)
    open(joinpath(dir, "status.log"), "a") do f
        JSON3.write(f, job_status)
    end
    return nothing
end
function fetch_status(dapr::MockEventService, job_id::String; timeout::Real)
    dapr.print_event && @info "[FETCH STATUS] $job_id"
    s = load_until_success(joinpath(dapr.save_dir, job_id, "status.log"); timeout)
    isempty(s) && return nothing
    return JSON3.read(s, JobStatus)
end
function save_state(dapr::MockEventService, job_id::AbstractString, res)
    key = "JUGSAW-JOB-RESULT:$(job_id)"
    dapr.print_event && @info "[$key] $res"
    # save to file
    ir, tt = julia2ir(res)
    dir = joinpath(dapr.save_dir, job_id)
    mkpath(dir)
    open(joinpath(dir, "result.jug"), "w") do f
        write(f, ir)
    end
    return nothing
end
function load_state(dapr::MockEventService, job_id::AbstractString, resdemo; timeout::Real)
    key = "JUGSAW-JOB-RESULT:$(job_id)"
    dapr.print_event && @info "Fetching [$key]"
    s = load_until_success(joinpath(dapr.save_dir, job_id, "result.jug"); timeout)
    isempty(s) && return nothing
    return ir2julia(s, resdemo)
end
function load_until_success(filename; interval=0.01, timeout=Inf)
    t0 = time()
    while time() - t0 < timeout
        if isfile(filename)
            return open(filename, "r") do f
                read(f, String)
            end
        end
        sleep(interval)
    end
    return ""
end

########################## Application Runtime
struct AppRuntime{ES<:AbstractEventService}
    app::AppSpecification
    dapr::ES
    channel::Channel{Job}
end

function AppRuntime(app::AppSpecification, dapr::AbstractEventService)
    channel = Channel{Job}() do ch
        for job in ch
            try
                res = fevalself(Call(job.demo.fcall.fname, job.payload.args, job.payload.kwargs))
                save_state(dapr, job.id, res)
                publish_status(dapr, JobStatus(id=job.id, status=succeeded))
            catch ex
                st_io = IOBuffer()
                showerror(st_io, CapturedException(ex, catch_backtrace()))
                println(String(take!(st_io)))
                publish_status(dapr, JobStatus(id=job.id, status=failed, description=string(ex)))
            end
        end
    end
    return AppRuntime(app, dapr, channel)
end

function addjob!(r::AppRuntime, job_id::String, created_at, created_by, adt::JugsawADT, thisdemo::JugsawDemo)
    fname, args, kwargs = adt.fields
    # IF tree is a function call, return an `object_id` for return value.
    #     recurse over args and kwargs to get `Call` parsed.
    newargs = ntuple(i->renderobj!(r, created_at, created_by, args.fields[i], thisdemo.fcall.args[i]), length(args.fields))
    newkwargs = typeof(thisdemo.fcall.kwargs)(ntuple(i->renderobj!(r, created_at, created_by, kwargs.fields[i], thisdemo.fcall.kwargs[i]), length(kwargs.fields)))
    # add task to the queue
    @info "task added to the queue: $job_id => $adt"
    job = Job(job_id, created_at, created_by, thisdemo, Payload(newargs, newkwargs))

    # submit job
    res = timedwait(get_timeout(r.dapr)) do
        put!(r.channel, job)
        publish_status(r.dapr, JobStatus(id=job.id, status=processing))
        true
    end
    if res != :ok
        publish_status(r.dapr, JobStatus(id=job.id, status=pending, description="Failed to submit job after $TIME_OUT seconds."))
    end
    return nothing
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

# if adt is a function call, launch a job and return an object getter, else, return an object.
function renderobj!(r::AppRuntime, created_at, created_by, adt, thisdemo)
    if adt isa JugsawADT && hasproperty(adt, :typename) && adt.typename == "JugsawIR.Call"
        fdemo = match_demo_or_throw(adt, r.app)
        object_id = uuid4()
        addjob!(r, object_id, created_at, created_by, adt, fdemo.fcall)
        # Return an object getter, which is a `Call` instance that fetches objects from the state_store.
        return object_getter(r.dapr, object_id, fdemo.result)
    else
        return JugsawIR.adt2julia(adt, thisdemo)
    end
end

# an object getter to load return values of a function call from the state store
function object_getter(dapr::AbstractEventService, object_id::String, resdemo)
    function getter(dapr, id::String, resdemo)
        res = load_state(dapr, id, resdemo)
        # rethrow a cached error
        res isa CachedError && Base.rethrow(res.exception)
        return res
    end
    Call(getter, (dapr, object_id), (;))
end


################### Server #################

function job_handler(r::AppRuntime, req::HTTP.Request)
    println(req.headers)
    println(req.body)
    evt = from_http(req.headers, req.body)
    # CloudEvent
    adt = JugsawIR.ir2adt(String(evt.data))
    @info "got job adt: $adt"

    # top level must be a function call
    # add jobs recursively to the queue
    try
        thisdemo = match_demo_or_throw(adt, r.app)
        addjob!(r, obj.id, obj.created_at, obj.created_by, adt, thisdemo)
        return HTTP.Response(200, "Job submitted!")
    catch e
        @info e
        return _error_response(e)
    end
end

function get_router(runtime::AppRuntime)
    r = HTTP.Router()

    HTTP.register!(r, "GET", "/healthz", _ -> JSON3.write((; status="OK")))
    HTTP.register!(r, "POST", "/events/jobs", req->job_handler(runtime, req))
    HTTP.register!(r, "GET", "/demos", _ -> ((demos, types) = JugsawIR.julia2ir(r.app); "[$demos, $types]"))
    HTTP.register!(r, "GET", "/api/{lang}", _ -> "")
    HTTP.register!(r, "GET", "/dapr/subscribe",
        _ -> JSON3.write([(pubsubname="jobs", topic="$(runtime.app.created_by).$(runtime.app.name).$(rumtime.app.ver)", route="/events/jobs")])
    )
    return r
end

function serve(runtime::AppRuntime, is_async::Bool=false, port::Int=8088)
    # release demo
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