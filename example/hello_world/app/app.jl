using HTTP
using JSON3
using EnumX
using CloudEvents
using DaprClients
using StructTypes
using TimeZones
using Dates
using UUIDs

JOB_PUB_SUB = "jugsaw-job-pubsub"
JOB_EVENT_PUB_SUB = "jugsaw-job-event-pubsub"
JOB_RESULT_STORE = "jugsaw-job-result-store"

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
    created_at::String
    created_by::String

    app::String
    func::String
    ver::String
    payload::Payload
end

Base.@kwdef struct JobEvent
    id::String = string(uuid4())
    job_id::String
    status::JobStatusEnum.T
    created_at::String = replace(string(now(tz"UTC")), "+00:00" => "Z")
    description::String = ""
end


publish(job_event::JobEvent) = publish_event(JOB_EVENT_PUB_SUB, string(job_event.status), job_event; headers=Pair{SubString{String},SubString{String}}["Content-Type"=>"application/json"])

# TODO: use register instead
greet(x::String="World") = "Hello, $x"

JOB_MANAGER = JobManager()

# register
JOB_MANAGER.tasks["greet"] = Channel() do ch
    for job in ch
        try
            res = greet(job.payload.args...; job.payload.kwargs...)
            save_state(JOB_RESULT_STORE, job.id, JSON3.write(res))
            publish(JobEvent(job_id=job.id, status=JobStatusEnum.succeeded))
        catch ex
            st_io = IOBuffer()
            showerror(st_io, CapturedException(ex, catch_backtrace()))
            println(String(take!(st_io)))

            publish(JobEvent(job_id=job.id, status=JobStatusEnum.failed, description=string(ex)))
        end
    end
end

function job_handler(req::HTTP.Request)
    println(req.headers)
    println(req.body)
    evt = from_http(req.headers, req.body)
    job = StructTypes.constructfrom(Job, evt[])
    println(job)
    submit_job(job)
    HTTP.Response(200, "Job submitted!")
end

TIME_OUT = 15

function submit_job(job::Job)
    if haskey(JOB_MANAGER.tasks, job.func)
        res = timedwait(TIME_OUT) do
            put!(JOB_MANAGER.tasks[job.func], job)
            publish(JobEvent(job_id=job.id, status=JobStatusEnum.processing))
            true
        end
        res == :ok || publish(JobEvent(job_id=job.id, status=JobStatusEnum.pending, description="Failed to submit job after $TIME_OUT seconds."))
    else
        publish(JobEvent(job_id=job.id, status=JobStatusEnum.failed, description="$(job.func) is not registered!"))
    end
end

function subscribe(req)
    user = get(ENV, "JUGSAW_USER_NAME", "test")
    app = get(ENV, "JUGSAW_APP_NAME", "helloworld")
    ver = get(ENV, "JUGSAW_APP_VERSION", "sha256:c849f3b6c7f5f621251a58d6c26722a97ea6b1f8b3c31ecdf2b7bab09b24b3f9")
    JSON3.write([(pubsubname=JOB_PUB_SUB, topic="$user.$app.$ver", route="/events/jobs")])
end

r = HTTP.Router()

HTTP.register!(r, "GET", "/healthz", _ -> JSON3.write((; status="OK")))
HTTP.register!(r, "POST", "/events/jobs", job_handler)
HTTP.register!(r, "GET", "/dapr/subscribe", subscribe)

#####

HTTP.serve(r, "0.0.0.0", 8088)
