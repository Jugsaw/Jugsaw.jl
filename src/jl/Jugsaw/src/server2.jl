module Server
using HTTP
using JugsawIR
using Dates: now, datetime2unix
using JugsawIR.JSON3
import CloudEvents
import DaprClients
import UUIDs
import ..AppSpecification, ..NoDemoException

export Job, JobStatus, JobSpec
export MockEventService, publish_status, fetch_status, save_state, load_state, get_timeout
export AppRuntime, addjob!

@enum JobStatusEnum starting processing pending succeeded failed canceled

struct JobSpec
    # meta information
    id::String
    created_at::Float64
    created_by::String
    maxtime::Float64

    # payload
    fname::String
    args::JugsawADT
    kwargs::JugsawADT
end

struct Job
    # meta information
    id::String
    created_at::Float64
    created_by::String
    maxtime::Float64

    # payload
    demo::JugsawDemo
    args::Tuple
    kwargs::NamedTuple
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
    timeout::Float64
    query_interval::Float64
end
function MockEventService(save_dir::String; print_event::Bool=true, timeout=1.0, query_interval=0.1)
    return MockEventService(print_event, save_dir, timeout, query_interval)
end
get_timeout(dapr::MockEventService) = dapr.timeout
get_query_interval(dapr::MockEventService) = dapr.query_interval
# update job status to Dapr
function publish_status(dapr::MockEventService, job_status::JobStatus)
    dapr.print_event && @info "[PUBLISH STATUS] $job_status"
    # log into file
    dir = joinpath(dapr.save_dir, job_status.id)
    mkpath(dir)
    filename = joinpath(dir, "status.log")
    if isfile(filename)
        open(filename, "a") do f
            write(f, "\n")
            JSON3.write(f, job_status)
        end
    else
        open(filename, "w") do f
            JSON3.write(f, job_status)
        end
    end
    return nothing
end
function fetch_status(dapr::MockEventService, job_id::String; timeout::Real)
    dapr.print_event && @info "[FETCH STATUS] $job_id"
    filename = joinpath(dapr.save_dir, job_id, "status.log")

    # load last line
    s = Ref{JobStatus}()
    status = timedwait(timeout; pollint=0.1) do
        if isfile(filename)
            s[] = JSON3.read(last(eachline(filename)), JobStatus)
            return true
        end
        return false
    end

    if status == :ok
        return status, s[]
    else
        return status, nothing
    end
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
    filename = joinpath(dapr.save_dir, job_id, "result.jug")

    s = Ref{String}()
    status = timedwait(timeout; pollint=0.1) do
        if isfile(filename)
            s[] = open(filename, "r") do f
                read(f, String)
            end
            return true
        end
        return false
    end

    if status == :ok
        return status, ir2julia(s[], resdemo)
    else
        return status, nothing
    end
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
                res = fevalself(Call(job.demo.fcall.fname, job.args, job.kwargs))
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

function addjob!(r::AppRuntime, jobspec::JobSpec)
    # Find the demo and parse the arguments
    created_at, created_by, maxtime, fname, args, kwargs = jobspec.created_at, jobspec.created_by, jobspec.maxtime, jobspec.fname, jobspec.args, jobspec.kwargs
    # match demo or throw
    thisdemo = match_demo(fname, args.typename, kwargs.typename, r.app)
    thisdemo === nothing && throw(NoDemoException(jobspec, r.app))

    # IF tree is a function call, return an `object_id` for return value.
    #     recurse over args and kwargs to get `Call` parsed.
    newargs = ntuple(i->renderobj!(r, created_at, created_by, maxtime, args.fields[i], thisdemo.fcall.args[i]), length(args.fields))
    newkwargs = typeof(thisdemo.fcall.kwargs)(ntuple(i->renderobj!(r, created_at, created_by, maxtime, kwargs.fields[i], thisdemo.fcall.kwargs[i]), length(kwargs.fields)))

    # add task to the queue
    job = Job(jobspec.id, created_at, created_by, maxtime, thisdemo, newargs, newkwargs)
    @info "adding job to the queue: $job"

    # submit job
    res = timedwait(get_timeout(r.dapr)) do
        put!(r.channel, job)
        publish_status(r.dapr, JobStatus(id=job.id, status=processing))
        true
    end
    if res != :ok
        publish_status(r.dapr, JobStatus(id=job.id, status=pending, description="Failed to submit job after $maxtime seconds."))
    end
    return job
end

# TODO: design a more powerful IR for chaining.
function match_demo(fname, args_type, kwargs_type, app::AppSpecification)
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
function renderobj!(r::AppRuntime, created_at, created_by, maxtime, adt, thisdemo)
    if adt isa JugsawADT && hasproperty(adt, :typename) && adt.typename == "JugsawIR.Call"
        object_id = string(UUIDs.uuid4())
        addjob!(r, JobSpec(object_id, created_at, created_by, maxtime, adt.fields...))
        # Return an object getter, which is a `Call` instance that fetches objects from the state_store.
        return object_getter(r.dapr, object_id, thisdemo; timeout=get_timeout(r.dapr)+maxtime)
    else
        return JugsawIR.adt2julia(adt, thisdemo)
    end
end

# an object getter to load return values of a function call from the state store
function object_getter(dapr::AbstractEventService, object_id::String, resdemo; timeout)
    function getter(dapr, id::String, resdemo)
        status, res = load_state(dapr, id, resdemo; timeout)
        # rethrow a cached error
        if status != :ok
            error("get object fail ($status): $object_id")
        end
        return res
    end
    Call(getter, (dapr, object_id, resdemo), (;))
end


################### Server #################

function job_handler(r::AppRuntime, evt::CloudEvents.CloudEvent)
    # top level must be a function call
    # add jobs recursively to the queue
    try
        # CloudEvent
        jobadt = JugsawIR.ir2adt(String(evt.data))
        job_id, created_at, created_by, maxtime, fname, args, kwargs = jobadt.fields
        jobspec = JobSpec(job_id, created_at, created_by, Int(maxtime), fname, args, kwargs)
        @info "get job: $jobspec"
        addjob!(r, jobspec)
        return HTTP.Response(200, "Job submitted!")
    catch e
        @info e
        return _error_response(e)
    end
end

function code_handler(r::AppRuntime, lang::String, endpoint::String, evt::CloudEvents.CloudEvent)
end

function get_router(runtime::AppRuntime)
    r = HTTP.Router()

    HTTP.register!(r, "GET", "/healthz", _ -> JSON3.write((; status="OK")))
    HTTP.register!(r, "POST", "/events/jobs", req->job_handler(runtime, from_http(req.headers, req.body)))
    HTTP.register!(r, "GET", "/demos", _ -> ((demos, types) = JugsawIR.julia2ir(r.app); "[$demos, $types]"))
    # TODO: we need context here!
    HTTP.register!(r, "GET", "/api/{lang}", _ -> code_handler(runtime, lang, endpoint, from_http(req.headers, req.body)))
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