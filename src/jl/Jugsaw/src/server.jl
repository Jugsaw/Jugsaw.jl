module Server
using HTTP
using JugsawIR
using Dates: now, datetime2unix
using JugsawIR.JSON3
import CloudEvents
import DaprClients
import UUIDs
import ..AppSpecification, ..NoDemoException, .._error_response, ..generate_code, .._error_msg, ..TimedOutException

export Job, JobStatus, JobSpec
export AbstractEventService, DaprService, FileEventService, InMemoryEventService, publish_status, fetch_status, save_object, load_object, load_object_as_ir, get_timeout
export AppRuntime, addjob!

@enum JobStatusEnum starting processing pending succeeded failed canceled

"""
    JobSpec

A job specified as a Jugsaw ADT.
"""
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

"""
    Job

A resolved job can be queued and executed in a `AppRuntime`.
"""
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

"""
    JobStatus

A job status.
"""
Base.@kwdef struct JobStatus
    id::String
    status::JobStatusEnum
    timestamp::Float64 = datetime2unix(now())
    description::String = ""
end

"""
    AbstractEventService

The abstract type for event service. Its concrete subtypes include
* [`DaprService`](@ref)
* [`FileEventService`](@ref)
* [`InMemoryEventService`](@ref)

### Required Interfaces
* [`get_timeout`](@ref)
* [`publish_event`](@ref)
* [`fetch_status`](@ref)
* [`save_object`](@ref)
* [`load_object`](@ref)
* [`load_object_as_ir`](@ref)
"""
abstract type AbstractEventService end

"""
    get_timeout(dapr::AbstractEventService) -> Float64

Returns the timeout of the event service in seconds.
"""
function get_timeout end

"""
    get_query_interval(dapr::AbstractEventService)::Float64

Returns the query time interval of the event service in seconds.
"""
function get_query_interval end

"""
    save_object(dapr::AbstractEventService, job_id::AbstractString, res) -> nothing

Save an object to the event service in the form of local or web storage.
The stored object can be loaded with [`load_object`](@ref) function.
"""
function save_object end

"""
    load_object(dapr::AbstractEventService, job_id::AbstractString, resdemo; timeout::Real) -> (status_code, object)

Load an object to the main memory. The return value is a tuple with the following two elements
* `status_code` is a symbol to indicate the status query result, which can be `:ok` or `:timed_out`
* `status` is an object if the `status_code` is `:ok`, otherwise, is `nothing`.

The keyword argument `timeout` is should be greater than the expected job run time.
"""
function load_object(dapr::AbstractEventService, job_id::AbstractString, resdemo; timeout::Real)
    status, obj = load_object_as_ir(dapr, job_id; timeout)
    if status == :ok
        return status, ir2julia(obj, resdemo)
    else
        return status, nothing
    end
end
"""
    load_object_as_ir(dapr::AbstractEventService, job_id::AbstractString; timeout::Real) -> (status_code, ir)

Similar to [`load_object`](@ref), but returns a Jugsaw IR instead. An object demo is not required.
"""
function load_object_as_ir end

"""
    publish_status(dapr::AbstractEventService, job_status::JobStatus) -> nothing

Publish the status of a job to the event service.
The published event can be accessed with [`fetch_status`](@ref) function.
"""
function publish_status end

"""
    fetch_status(dapr::AbstractEventService, job_id::String; timeout::Real=get_timeout(dapr)) -> (status_code, status)

Get the status of a job. The return value is a tuple with the following two elements
* `status_code` is a symbol to indicate the status query result, which can be `:ok` or `:timed_out`
* `status` is a `JobStatus` object if the `status_code` is `:ok`, otherwise, is `nothing`.
"""
function fetch_status end

"""
    DaprService <: AbstractEventService

Dapr event service for storing and fetching events and results.
Please check [`AbstractEventService`](@ref) for implemented interfaces.
"""
Base.@kwdef struct DaprService <: AbstractEventService
    timeout::Float64 = 15.0
    query_interval::Float64 = 0.1
    pub_sub::String = "jobs"
    result_store::String = "job-result-store"
end
get_timeout(dapr::DaprService) = dapr.timeout
get_query_interval(dapr::DaprService) = dapr.query_interval
function publish_status(dapr::DaprService, job_status::JobStatus)
    return DaprClients.publish_event(dapr.pub_sub, string(job_status.status), job_status; headers=Pair{SubString{String},SubString{String}}["Content-Type"=>"application/json"])
end
function fetch_status(dapr::DaprService, job_id::String; timeout::Real=get_timeout(dapr))
    error("Not implemented")
end
function save_object(dapr::DaprService, job_id::AbstractString, res)
    key = "JUGSAW-JOB-RESULT:$(job_id)"
    return DaprClients.save_object(dapr.result_store, key, JSON3.write(res))
end
function load_object_as_ir(dapr::DaprService, job_id::AbstractString; timeout::Real)
    error("Not implemented")
end

############# The mock event service for printing job status and saving results
"""
    FileEventService <: AbstractEventService

Mocked event service for storing and fetching events and results from the local file system.
Please check [`AbstractEventService`](@ref) for implemented interfaces.
"""
struct FileEventService <: AbstractEventService
    print_event::Bool
    save_dir::String
    timeout::Float64
    query_interval::Float64
end
function FileEventService(save_dir::String; print_event::Bool=true, timeout=1.0, query_interval=0.1)
    return FileEventService(print_event, save_dir, timeout, query_interval)
end
get_timeout(dapr::FileEventService) = dapr.timeout
get_query_interval(dapr::FileEventService) = dapr.query_interval
# update job status to Dapr
function publish_status(dapr::FileEventService, job_status::JobStatus)
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
function fetch_status(dapr::FileEventService, job_id::String; timeout::Real=get_timeout(dapr))
    dapr.print_event && @info "[FETCH STATUS] $job_id"
    filename = joinpath(dapr.save_dir, job_id, "status.log")

    # load last line
    s = Ref{JobStatus}()
    status = timedwait(timeout; pollint=get_query_interval(dapr)) do
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
function save_object(dapr::FileEventService, job_id::AbstractString, res)
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
function load_object_as_ir(dapr::FileEventService, job_id::AbstractString; timeout::Real)
    key = "JUGSAW-JOB-RESULT:$(job_id)"
    dapr.print_event && @info "Fetching [$key]"
    filename = joinpath(dapr.save_dir, job_id, "result.jug")

    s = Ref("")
    status = timedwait(timeout; pollint=get_query_interval(dapr)) do
        if isfile(filename)
            s[] = open(filename, "r") do f
                read(f, String)
            end
            return true
        end
        return false
    end
    return status, s[]
end

"""
    InMemoryEventService <: AbstractEventService

An event service for storing and fetching events and results from the the main memory.
Please check [`AbstractEventService`](@ref) for implemented interfaces.

When deploying Jugsaw locally, read-write through local storage might be too slow.
"""
struct InMemoryEventService <: AbstractEventService
    print_event::Bool
    object_store::Dict{String, Any}
    status_store::Dict{String, JobStatus}
end
function InMemoryEventService(; print_event::Bool=true)
    return InMemoryEventService(print_event, Dict{String, Any}(), Dict{String, JobStatus}())
end
get_timeout(dapr::InMemoryEventService) = 0.0
get_query_interval(dapr::InMemoryEventService) = 0.1
# update job status to Dapr
function publish_status(dapr::InMemoryEventService, job_status::JobStatus)
    dapr.print_event && @info "[PUBLISH STATUS] $job_status"
    # log into file
    dapr.status_store[job_status.id] = job_status
    return nothing
end
function fetch_status(dapr::InMemoryEventService, job_id::String; timeout::Real=get_timeout(dapr))
    dapr.print_event && @info "[FETCH STATUS] $job_id"
    if haskey(dapr.status_store, job_id)
        return :ok, dapr.status_store[job_id]
    else
        return :timed_out, nothing
    end
end
function save_object(dapr::InMemoryEventService, job_id::AbstractString, res)
    key = "JUGSAW-JOB-RESULT:$(job_id)"
    dapr.print_event && @info "[$key] $res"
    # save to file
    dapr.object_store[job_id] = res
    return nothing
end
function load_object(dapr::InMemoryEventService, job_id::AbstractString, resdemo; timeout::Real)
    key = "JUGSAW-JOB-RESULT:$(job_id)"
    dapr.print_event && @info "Fetching [$key]"
    s = Ref{Any}(nothing)
    # this is because jobs are handled asynchronously
    status = timedwait(timeout; pollint=get_query_interval(dapr)) do
        if haskey(dapr.object_store, job_id)
            s[] = dapr.object_store[job_id]
            return true
        end
        return false
    end
    return status, s[]
end
function load_object_as_ir(dapr::InMemoryEventService, job_id::AbstractString; timeout::Real)
    status, obj = load_object(dapr, job_id, nothing; timeout)
    return status, julia2ir(obj)[1]
end

########################## Application Runtime
"""
    AppRuntime{ES<:AbstractEventService}

The application instance wrapped with run time information.

### Fields
* `app` is a [`AppSpecification`](@ref) instance.
* `dapr` is a [`AbstractEventService`](@ref) instance for handling result storing and job status updating.
* `channel` is a [channel](https://docs.julialang.org/en/v1/base/parallel/#Channels) of jobs to be processed.
"""
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
                save_object(dapr, job.id, res)
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
    if thisdemo === nothing
        err = NoDemoException(jobspec, r.app)
        publish_status(r.dapr, JobStatus(id=jobspec.id, status=failed, description=_error_msg(err)))
        throw(err)
    end

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
        # Return an object getter, which is a `Call` instance that fetches objects from the event service.
        return object_getter(r.dapr, object_id, thisdemo; timeout=get_timeout(r.dapr)+maxtime)
    else
        return JugsawIR.adt2julia(adt, thisdemo)
    end
end

# an object getter to load return values of a function call from the state store
function object_getter(dapr::AbstractEventService, object_id::String, resdemo; timeout)
    function getter(dapr, id::String, resdemo)
        status, res = load_object(dapr, id, resdemo; timeout)
        # rethrow a cached error
        if status != :ok
            error("get object fail ($status): $object_id")
        end
        return res
    end
    Call(getter, (dapr, object_id, resdemo), (;))
end

################### Server #################

function job_handler(r::AppRuntime, req::HTTP.Request)
    # top level must be a function call
    # add jobs recursively to the queue
    try
        evt = CloudEvents.from_http(req.headers, req.body)
        # CloudEvent
        jobadt = JugsawIR.ir2adt(String(evt.data))
        job_id, created_at, created_by, maxtime, fname, args, kwargs = jobadt.fields
        jobspec = JobSpec(job_id, created_at, created_by, maxtime, fname, args, kwargs)
        @info "get job: $jobspec"
        addjob!(r, jobspec)
        return HTTP.Response(200, "Job submitted!")
    catch e
        @info e
        return _error_response(e)
    end
end

function fetch_handler(r::AppRuntime, req::HTTP.Request)
    # NOTE: JSON3 errors
    s = String(req.body)
    @info "fetching: $s"
    job_id = JSON3.read(s)["job_id"]
    timeout = get_timeout(r.dapr)
    status, ir = load_object_as_ir(r.dapr, job_id; timeout=timeout)
    if status != :ok
        return _error_response(ErrorException("object not ready yet!"))
    elseif status == :timed_out
        return _error_response(TimedOutException(job_id, timeout))
    else
        return HTTP.Response(200, ["Content-Type" => "application/json"], ir)
    end
end

function demos_handler(app::AppSpecification)
    (demos, types) = JugsawIR.julia2ir(app)
    ir = "[$demos, $types]"
    return HTTP.Response(200, ["Content-Type" => "application/json"], ir)
end

function code_handler(req::HTTP.Request, app::AppSpecification)
    # get language
    params = HTTP.getparams(req)
    lang = params["lang"]
    # get request
    adt = JugsawIR.ir2adt(String(req.body))
    endpoint, fcall = adt.fields
    fname, args, kwargs = fcall.fields
    demo = match_demo(fname, args.typename, kwargs.typename, app)
    if demo === nothing
        return _error_response(NoDemoException(fcall, app))
    else
        try
            code = generate_code(lang, endpoint, app.name, fcall, demo.fcall)
            return HTTP.Response(200, ["Content-Type" => "application/json"], JSON3.write((; code=code)))
        catch e
            return _error_response(e)
        end
    end
end

struct RemoteRoute end
struct LocalRoute end

function get_router(::LocalRoute, runtime::AppRuntime)
    r = HTTP.Router()

    HTTP.register!(r, "GET", "/healthz", _ -> JSON3.write((; status="OK")))
    HTTP.register!(r, "POST", "/events/jobs", req->job_handler(runtime, req))
    HTTP.register!(r, "GET", "/events/jobs/fetch", req -> fetch_handler(runtime, req))
    HTTP.register!(r, "GET", "/demos", _ -> demos_handler(runtime.app))
    # TODO: we need context about endpoint here!
    HTTP.register!(r, "GET", "/api/{lang}", req -> code_handler(req, runtime.app))
    # TODO: complete subscribe
    HTTP.register!(r, "GET", "/dapr/subscribe",
        _ -> JSON3.write([(pubsubname="jobs", topic="$(runtime.app.created_by).$(runtime.app.name).$(rumtime.app.ver)", route="/events/jobs")])
    )
    return r
end

function get_router(::RemoteRoute, runtime::AppRuntime)
    r = HTTP.Router()
    # job
    HTTP.register!(r, "POST", "/v1/proj/{project}/app/{appname}/ver/{version}/func/{fname}",
        req->job_handler(runtime, req)
    )
    # fetch
    HTTP.register!(r, "GET", "/v1/job/{job_id}/result",
        req -> fetch_handler(runtime, req)
    )
    # demos
    HTTP.register!(r, "GET", "/v1/proj/{project}/app/{appname}/ver/{version}/func",
        req -> demos_handler(runtime.app)
    )
    # api, NOTE: this is new!!!!
    HTTP.register!(r, "GET", "/v1/proj/{project}/app/{appname}/ver/{version}/func/{fname}/api/{lang}",
        req -> code_handler(req, runtime.app)
    )
    # healthz
    HTTP.register!(r, "GET", "/v1/proj/{project}/app/{appname}/ver/{version}/healthz",
        req -> JSON3.write((; status="OK"))
    )
    # subscribe
    HTTP.register!(r, "GET", "/dapr/subscribe",
         req-> JSON3.write([(pubsubname="jobs", topic="$(runtime.app.created_by).$(runtime.app.name).$(rumtime.app.ver)", route="/events/jobs")])
    )
    return r
end

"""
    serve(runtime::AppRuntime; is_async::Bool=false, port::Int=8088, localmode::Bool=true)

Make this application online.

### Arguments
* `runtime` is an [`AppRuntime`](@ref) instance.

### Keyword arguments
* `is_async` is a switch to turn on the asynchronous mode for debugging.
* `port` is the port to serve the application.
* `localmode` is a switch to serve in local mode with a simplified routing table.
In the local mode, the project name and application name are not required in the request url.
"""
function serve(runtime::AppRuntime; is_async::Bool=false, port::Int=8088, localmode::Bool=true)
    # release demo
    r = get_router(localmode ? LocalRoute() : RemoteRoute(), runtime)
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
# dapr = FileEventService(".jugsaw_workspace")
# register!(runtime, dapr, "greet", greet)

end