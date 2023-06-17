from cloudevents.http import from_http
from fastapi import FastAPI, Request
from dapr.clients import DaprClient

from .job import JobEvent, JobStatusEnum
from .config import get_config

app = FastAPI()


# Register Dapr pub/sub subscriptions
@app.get("/dapr/subscribe")
def subscribe():
    config = get_config()
    return [
        {"pubsubname": config.job_event_channel, "topic": x, "route": "jobs"}
        for x in JobStatusEnum.__members__.keys()
    ]


# Dapr subscription in /dapr/subscribe sets up this route
@app.post("/jobs")
async def update_job_event(request: Request):
    # TODO: support web hooks
    body = await request.body()
    event = from_http(dict(request.headers), body)
    job_evt = JobEvent.parse_obj(event.data)

    config = get_config()

    with DaprClient() as client:
        client.save_state(
            config.job_event_store,
            job_evt.id,
            job_evt.json(),
            state_metadata={"contentType": "application/json"},
        )
