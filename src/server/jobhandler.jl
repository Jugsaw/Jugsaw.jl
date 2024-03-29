@enum JobStatusEnum starting processing pending succeeded failed canceled

const JSON_HEADER = ["Content-Type" => "application/json", "Access-Control-Allow-Origin" => "*",
                        "Access-Control-Allow-Headers" => "*",
                        "Access-Control-Allow-Methods" => "GET,POST,OPTIONS"]
const SIMPLE_HEADER = ["Access-Control-Allow-Origin" => "*",
                        "Access-Control-Allow-Headers" => "*",
                        "Access-Control-Allow-Methods" => "GET,POST,OPTIONS"]

function _error_response(e::Exception)
    HTTP.Response(400, JSON_HEADER, JSON3.write((; error=_error_msg(e))))
end

"""
$(TYPEDEF)

A resolved job can be queued and executed in a [`AppRuntime`](@ref).

### Fields
$(TYPEDFIELDS)
"""
struct Job{FT, argsT, kwargsT}
    # meta information
    id::String
    created_at::Float64
    created_by::String
    maxtime::Float64

    # payload
    fcall::Call{FT, argsT, kwargsT}
end

"""
$(TYPEDEF)

A job status that can be pubished to [`AbstractEventService`](@ref).

### Fields
$(TYPEDFIELDS)
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
* [`InMemoryEventService`](@ref)

### Required Interfaces
* [`publish_status`](@ref)
* [`fetch_status`](@ref)
* [`save_object`](@ref)
* [`load_object`](@ref)
* [`load_object_as_ir`](@ref)
"""
abstract type AbstractEventService end

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
        return status, JugsawIR.read_object(obj, resdemo)
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
    fetch_status(dapr::AbstractEventService, job_id::String; timeout::Real=get_timeout()) -> (status_code, status)

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
    query_interval::Float64 = 0.1
    pub_sub::String = "jobs"                    # TODO: change to environment variable.
    result_store::String = "job-result-store"   # TODO: change to environment variable.
end
function publish_status(dapr::DaprService, job_status::JobStatus)
    return DaprClients.publish_event(dapr.pub_sub, string(job_status.status), job_status; headers=Pair{SubString{String},SubString{String}}["Content-Type"=>"application/json"])
end
function fetch_status(dapr::DaprService, job_id::String; timeout::Real=get_timeout())
    error("Not implemented")
end
function save_object(dapr::DaprService, job_id::AbstractString, res)
    key = "JUGSAW-JOB-RESULT:$(job_id)"
    return DaprClients.save_object(dapr.result_store, key, JSON3.write(res))
end
function load_object_as_ir(dapr::DaprService, job_id::AbstractString; timeout::Real)
    error("Not implemented")
end

"""
$(TYPEDEF)

An event service for storing and fetching events and results from the the main memory.
Please check [`AbstractEventService`](@ref) for implemented interfaces.

### Fields
$(TYPEDFIELDS)
"""
struct InMemoryEventService <: AbstractEventService
    print_event::Bool
    object_store::Dict{String, Any}
    status_store::Dict{String, JobStatus}
end
function InMemoryEventService(; print_event::Bool=true)
    return InMemoryEventService(print_event, Dict{String, Any}(), Dict{String, JobStatus}())
end
# update job status to Dapr
function publish_status(dapr::InMemoryEventService, job_status::JobStatus)
    dapr.print_event && @info "[PUBLISH STATUS] $job_status"
    # log into file
    dapr.status_store[job_status.id] = job_status
    return nothing
end
function fetch_status(dapr::InMemoryEventService, job_id::String; timeout::Real=get_timeout())
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
    status = timedwait(timeout; pollint=get_query_interval()) do
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
    return status, JugsawIR.write_object(obj)
end

########################## Application Runtime
"""
$(TYPEDEF)

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
                res = fevalself(job.fcall)
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

# submit a job to the channel
function submitjob!(r::AppRuntime, job::Job)
    @info "adding job to the queue: $job"
    res = timedwait(get_timeout()) do
        put!(r.channel, job)
        publish_status(r.dapr, JobStatus(id=job.id, status=processing))
        true
    end
    if res != :ok
        publish_status(r.dapr, JobStatus(id=job.id, status=pending, description="Failed to submit job after $maxtime seconds."))
    end
    return job
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