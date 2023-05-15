using HTTP
using JSON3
using EnumX
using CloudEvents
using DaprClients
using StructTypes
using Dates

JOB_PUB_SUB = "jobs"
JOB_RESULT_STORE = "job-result-store"
JOB_RESULT_KEY_FORMAT = k -> "JUGSAW-JOB-RESULT:$k"

@enumx JobStatusEnum starting processing pending succeeded failed canceled

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
    status::JobStatusEnum.T
    timestamp::Float64 = datetime2unix(now())
    description::String = ""
end


# TODO: use register instead
greet(x::String="World") = "Hello, $x!"

JOB_MANAGER = JobManager()

# register
JOB_MANAGER.tasks["greet"] = Channel() do ch
    for job in ch
        try
            res = greet(job.payload.args...; job.payload.kwargs...)
            save_state(JOB_RESULT_STORE, JOB_RESULT_KEY_FORMAT(job.id), JSON3.write(res))
            publish(JobStatus(id=job.id, status=JobStatusEnum.succeeded))
        catch ex
            publish(JobStatus(id=job.id, status=JobStatusEnum.failed, description=string(ex)))
            # TODO: record stack trace
        end
    end
end

function job_handler(req::HTTP.Request)
    println(req.headers)
    println(req.body)
    evt = from_http(req.headers, JSON3.read(req.body))
    job = StructTypes.constructfrom(Job, evt[])
    println(job)
    submit_job(job)
end

TIME_OUT = 1

function submit_job(job::Job)
    if haskey(JOB_MANAGER.tasks, job.func)
        res = timedwait(TIME_OUT) do
            put!(JOB_MANAGER.tasks[job.func], job)
            publish(JobStatus(id=job.id, status=JobStatusEnum.processing))
            true
        end
        res == :ok || publish(JobStatus(id=job.id, status=JobStatusEnum.pending, description="Failed to submit job after $TIME_OUT seconds."))
    else
        publish(JobStatus(id=job.id, status=JobStatusEnum.failed, description="$(job.func) is not registered!"))
    end
end

publish(job_status::JobStatus) = publish_event(JOB_PUB_SUB, string(job_status.status), JSON3.write(job_status))

r = HTTP.Router()

HTTP.register!(r, "GET", "/healthz", _ -> JSON3.write((; status="OK")))
HTTP.register!(r, "POST", "/events/jobs", job_handler)
HTTP.register!(
    r,
    "GET",
    "/dapr/subscribe",
    _ -> JSON3.write([(pubsubname="jobs", topic="jugsaw.helloworld.latest", route="/events/jobs")])
)


#####

HTTP.serve(r, "0.0.0.0", 8088)
