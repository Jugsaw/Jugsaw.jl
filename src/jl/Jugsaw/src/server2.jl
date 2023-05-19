module Server
using HTTP
using JugsawIR.JSON3
import CloudEvents
import DaprClients
using Dates

@enum JobStatusEnum starting processing pending succeeded failed canceled

Base.@kwdef struct JobManager
    tasks::Dict = Dict()
end

struct Payload
    args::Any
    kwargs::Any
end

struct Job
    id::String
    created_at::Float64
    created_by::String

    app::String
    func::String
    ver::String
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

struct EchoService <: AbstractEventService
end
get_timeout(::EchoService) = 1.0
# update job status to Dapr
function publish(dapr::EchoService, job_status::JobStatus)
    @info "[STATUS] $job_status"
    # log into file
    nothing
end
function save_state(dapr::EchoService, job::Job, res)
    key = "JUGSAW-JOB-RESULT:$(job.id)"
    @info "[$key] $res"
    # save to file
    nothing
end

function register!(man::JobManager, dapr::AbstractEventService, fname::String, f)
    # register
    man.tasks[fname] = Channel() do ch
        for job in ch
            try
                res = f(job.payload.args...; job.payload.kwargs...)
                save_state(dapr, job, JSON3.write(res))
                publish(dapr, JobStatus(id=job.id, status=succeeded))
            catch ex
                st_io = IOBuffer()
                showerror(st_io, CapturedException(ex, catch_backtrace()))
                println(String(take!(st_io)))

                publish(dapr, JobStatus(id=job.id, status=failed, description=string(ex)))
            end
        end
    end
end

function job_handler(man::JobManager, dapr::AbstractEventService, req::HTTP.Request)
    println(req.headers)
    println(req.body)
    evt = from_http(req.headers, req.body)
    job = StructTypes.constructfrom(Job, evt[])
    println(job)
    submit_job(man, dapr, job)
    HTTP.Response(200, "Job submitted!")
end

function submit_job(man::JobManager, dapr::AbstractEventService, job::Job)
    if haskey(man.tasks, job.func)
        res = timedwait(get_timeout(dapr)) do
            put!(man.tasks[job.func], job)
            publish(dapr, JobStatus(id=job.id, status=processing))
            true
        end
        res == :ok || publish(dapr, JobStatus(id=job.id, status=pending, description="Failed to submit job after $TIME_OUT seconds."))
    else
        publish(dapr, JobStatus(id=job.id, status=failed, description="$(job.func) is not registered!"))
    end
end

function get_router(man::JobManager, dapr::AbstractEventService)
    r = HTTP.Router()

    HTTP.register!(r, "GET", "/healthz", _ -> JSON3.write((; status="OK")))
    HTTP.register!(r, "POST", "/events/jobs", req->job_handler(man, dapr, req))
    HTTP.register!(
        r,
        "GET",
        "/dapr/subscribe",
        _ -> JSON3.write([(pubsubname="jobs", topic="jugsaw.helloworld.latest", route="/events/jobs")])
    )
    return r
end

function serve(man::JobManager, dapr::AbstractEventService, dir=nothing; is_async::Bool=false, port::Int=8088)
    dir === nothing || save_demos(dir, runtime.app)
    r = get_router(man, dapr)
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


# man = JobManager()
# dapr = EchoService(".jugsaw_workspace")
# register!(man, dapr, "greet", greet)

end