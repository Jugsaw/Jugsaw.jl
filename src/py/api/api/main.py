import json
from typing_extensions import Annotated
from fastapi import Depends, FastAPI, HTTPException, Request, status
from dapr.clients import DaprClient

from .auth import (
    ApiKey,
    get_keys_by_uid,
    get_uid_from_api_key,
    get_uid_from_jwt_token,
    try_create_api_key,
    try_delete_key,
)
from .job import Job, JobEvent, JobStatusEnum, Payload
from .config import get_config


app = FastAPI(title="Jugsaw API")

#####


@app.get("/v1/proj", tags=["api"])
async def list_projects(
    uid: Annotated[str, Depends(get_uid_from_api_key)]
) -> list[str]:
    # TODO: pagination
    ...


@app.get("/v1/proj/{proj}", tags=["api"])
async def describe_project(
    proj: str, uid: Annotated[str, Depends(get_uid_from_api_key)]
) -> list[str]:
    # TODO: pagination
    ...


@app.get("/v1/proj/{proj}/app/{app}", tags=["api"])
async def list_applications(
    proj: str, app: str, uid: Annotated[str, Depends(get_uid_from_api_key)]
) -> list[str]:
    # TODO: pagination
    ...


@app.get("/v1/proj/{proj}/app/{app}/ver/{ver}", tags=["api"])
async def describe_application(
    proj: str,
    app: str,
    uid: Annotated[str, Depends(get_uid_from_api_key)],
    ver: str,
) -> str:
    ...


@app.get("/v1/proj/{proj}/app/{app}/ver/{ver}/func", tags=["api"])
async def list_functions(
    uid: Annotated[str, Depends(get_uid_from_api_key)],
    proj: str,
    app: str,
    ver: str,
) -> str:
    ...


@app.get("/v1/proj/{proj}/app/{app}/ver/{ver}/func/{func}", tags=["api"])
async def describe_function(
    proj: str,
    app: str,
    func: str,
    uid: Annotated[str, Depends(get_uid_from_api_key)],
    ver: str,
) -> str:
    ...


@app.post("/v1/proj/{proj}/app/{app}/ver/{ver}/func/{func}", tags=["api"])
async def submit_job(
    proj: str,
    app: str,
    ver: str,
    func: str,
    payload: Payload,
    uid: Annotated[str, Depends(get_uid_from_api_key)],
) -> str:
    config = get_config()

    with DaprClient() as client:
        job = Job(created_by=uid, app=app, func=func, ver=ver, payload=payload)
        client.save_state(config.job_store, job.id, job.json())
        client.publish_event(
            config.job_channel,
            f"{proj}.{app}.{ver}",
            job.json(),
            data_content_type="application/json",
        )
        client.publish_event(
            config.job_channel,
            JobStatusEnum.starting,
            JobEvent(job_id=job.id, status=JobStatusEnum.starting).json(),
            data_content_type="application/json",
        )
        return job.id


@app.get("/v1/job/{job_id}", tags=["api"])
async def describe_job(
    uid: Annotated[str, Depends(get_uid_from_api_key)], job_id: str
) -> Job:
    config = get_config()
    with DaprClient() as client:
        res = client.get_state(config.job_store, job_id)
        if res.data:
            job = Job.parse_raw(res.data)
            if job.created_by == uid:
                return job
            else:
                raise HTTPException(
                    status_code=status.HTTP_403_FORBIDDEN,
                    detail=f"Job[{job_id}] is not owned by {uid}",
                )
        else:
            raise HTTPException(status_code=404, detail=f"Job[{job_id}] not found")


@app.get("/v1/job/{job_id}/result", tags=["api"])
async def get_job_result(
    uid: Annotated[str, Depends(get_uid_from_api_key)], job_id: str
):
    config = get_config()
    with DaprClient() as client:
        res = client.get_state(config.job_result_store, job_id)
        if res.data:
            # TODO: make sure the result is create by `uid`
            # Maybe restrict the scope?
            return res.json()  # ??? plain text or json?
        else:
            raise HTTPException(
                status_code=404, detail=f"Job[{job_id}] result not found"
            )


@app.get("/v1/job/{job_id}/events", tags=["api"])
async def get_job_events(
    uid: Annotated[str, Depends(get_uid_from_api_key)], job_id: str
) -> list[JobEvent]:
    config = get_config()
    with DaprClient() as client:
        query = {"filter": {"EQ": {"job_id": job_id}}, "sort": [{"key": "timestamp"}]}
        resp = client.query_state(config.job_event_store, query=json.dumps(query))
        return [JobEvent.parse_raw(r.value) for r in resp.results]


@app.delete("/v1/job/{job_id}", tags=["api"])
async def cancel_job(job_id: str, uid: Annotated[str, Depends(get_uid_from_api_key)]):
    ...


#####


@app.get("/v1/key", tags=["account"])
async def get_keys(
    uid: Annotated[str, Depends(get_uid_from_jwt_token)]
) -> list[ApiKey]:
    return get_keys_by_uid(uid)


@app.post("/v1/key/api/{key_name}", tags=["account"])
async def create_api_key(
    key_name: str,
    uid: Annotated[str, Depends(get_uid_from_jwt_token)],
) -> ApiKey:
    return try_create_api_key(uid, key_name)


@app.post("/v1/key/registry/{key_name}", tags=["account"])
async def create_or_update_registry_key(
    key_name: str,
    uid: Annotated[str, Depends(get_uid_from_jwt_token)],
) -> ApiKey:
    return try_create_registry_key(uid, key_name)


@app.delete("/v1/key", tags=["account"])
async def delete_api_key(
    key_name: str,
    uid: Annotated[str, Depends(get_uid_from_jwt_token)],
):
    return try_delete_key(uid, key_name)


#####


@app.get("/v1/jobs", tags=["account"])
async def get_user_jobs(
    uid: Annotated[str, Depends(get_uid_from_jwt_token)]
) -> list[str]:
    ...


@app.get("/v1/apps", tags=["account"])
async def get_user_apps(
    uid: Annotated[str, Depends(get_uid_from_jwt_token)]
) -> list[str]:
    ...


#####


@app.get("/v1/ping/api", tags=["ping"])
async def ping_api(uid: Annotated[str, Depends(get_uid_from_api_key)]) -> str:
    return "pong"


@app.get("/v1/ping/key", tags=["ping"])
async def ping_key(uid: Annotated[str, Depends(get_uid_from_jwt_token)]) -> str:
    return "pong"


#####
# Dapr
#####

from cloudevents.http import from_http
from fastapi import Security
from fastapi.security import APIKeyHeader
from typing import Optional

DAPR_API_TOKEN = APIKeyHeader(
    name="dapr-api-token", scheme_name="Dapr API Token", auto_error=False
)


def verify_dapr_token(token: Optional[str] = Depends(DAPR_API_TOKEN)):
    config = get_config()
    if config.dapr_api_token is not None:
        if token != config.dapr_api_token:
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED, detail="Internal call only!"
            )


@app.get("/dapr/subscribe", dependencies=[Security(verify_dapr_token)])
def subscribe():
    config = get_config()
    return [
        {"pubsubname": config.job_channel, "topic": x, "route": "/events/jobs"}
        for x in JobStatusEnum.__members__.keys()
    ]


@app.post("/events/jobs", dependencies=[Security(verify_dapr_token)])
async def update_job_status(request: Request):
    config = get_config()

    body = await request.body()
    event = from_http(dict(request.headers), body)
    job_evt = JobEvent.parse_obj(event.data)

    with DaprClient() as client:
        client.save_state(config.job_event_store, job_evt.id, job_evt.json())
