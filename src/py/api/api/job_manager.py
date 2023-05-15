from cloudevents.http import from_http
from fastapi import FastAPI, Request
from dapr.clients import DaprClient

from .job import JobEvent, JobStatus, JobStatusEnum
from .config import get_config

app = FastAPI()


# Register Dapr pub/sub subscriptions
@app.get("/dapr/subscribe")
def subscribe():
    config = get_config()
    return [
        {"pubsubname": config.job_channel, "topic": x, "route": "jobs"}
        for x in JobStatusEnum.__members__.keys()
    ]


# Dapr subscription in /dapr/subscribe sets up this route
@app.post("/jobs")
async def update_job_status(request: Request):
    # TODO: support web hooks
    body = await request.body()
    event = from_http(dict(request.headers), body)
    job_evt = JobEvent.parse_obj(event.data)

    config = get_config()

    with DaprClient() as client:
        resp = client.get_state(
            config.job_store, config.job_key_format.format(job_evt.id)
        )
        if resp.data:
            job_state = JobStatus.parse_raw(resp.data)
            job_state.events.append(job_evt)
            etag = resp.etag
            client.save_state(
                config.job_store,
                config.job_key_format.format(job_id=job_evt.id),
                job_state.json(),
                etag,
            )
        else:
            raise Exception(f"Job[{job_evt.id}] not found")
