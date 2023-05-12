using HTTP
using JSON3
using EnumX
using CloudEvents
using DaprClients
using StructTypes
using Dates

JOB_PUB_SUB = "jobs"
JOB_STATUS_STORE = "jobstatus"
JOB_RESULT_STORE = "jobresult"

@enumx JobStatusEnum starting processing pending successed failed canceled

Base.@kwdef struct JobManager
    tasks::Dict = Dict()
end

# TODO: use register instead
greet(x::String="World") = "Hello, $x!"

JOB_MANAGER = JobManager()
JOB_MANAGER.tasks["greet"] = Channel() do ch
    for job in ch
        try
            res = greet(JSON3.read(job.data))
            # TODO: save data
            update_job_status(job, JobStatus.successed)
        catch
            update_job_status(job, JobStatus.failed)
        end
    end
end

struct Job
    id::String
    created_at::Float64
    created_by::String

    app::String
    func::String
    ver::String
    data::Vector{UInt8}
end

Base.@kwdef struct JobStatus
    job_id::String
    status::JobStatusEnum.T
    timestamp::Float64 = datetime2unix(now())
    description::String = ""
end

function job_handler(req::HTTP.Request)::HTTP.Response
    println(req.headers)
    println(req.body)
    evt = from_http(req.headers, req.body)
    job = StructTypes.constructfrom(Job, evt[])
    if try_run_job(job)
        update_job_status(job, JobStatusEnum.processing)
    else
        update_job_status(job, JobStatusEnum.pending)
    end
end

function try_run_job(job::Job)
    if haskey(JOB_MANAGER.tasks, job.func)
        :ok == timedwait(1) do
            put!(JOB_MANAGER.tasks[job.func], job)
            true
        end
    end
    false
end

function update_job_status(job, status::JobStatusEnum.T)
    publish_event(JOB_PUB_SUB, string(status), JSON3.write(JobStatus(job_id=job.id, status=status)))
end

r = HTTP.Router()

HTTP.register!(r, "GET", "/healthz", _ -> JSON3.write((; status="OK")))
HTTP.register!(r, "POST", "/events/jobs/starting", job_handler)
HTTP.register!(
    r,
    "GET",
    "/dapr/subscribe",
    _ -> JSON3.write([(pubsubname="jobs", topic="starting", route="/events/jobs/starting")])
)


#####

HTTP.serve(r, "0.0.0.0", 8088)
