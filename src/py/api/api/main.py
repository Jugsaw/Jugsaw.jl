from typing_extensions import Annotated
from fastapi import Depends, FastAPI, HTTPException, status
from dapr.clients import DaprClient
import json

from .auth import (
    JugsawApiKey,
    User,
    delete_api_key_by_uid_name,
    get_api_keys_by_uid,
    get_uid_by_api_key,
    get_uid_from_jwt_token,
    get_user_from_jwt_token,
    try_create_api_key,
    try_create_registry_key,
)
from .job import Job, JobEvent, JobStatusEnum, Payload
from .config import get_config


app = FastAPI(title="Jugsaw API")

#####


@app.get("/v1/proj", tags=["api"])
async def list_projects(uid: Annotated[str, Depends(get_uid_by_api_key)]) -> list[str]:
    # TODO: pagination
    ...


@app.get("/v1/proj/{proj}", tags=["api"])
async def describe_project(
    proj: str, uid: Annotated[str, Depends(get_uid_by_api_key)]
) -> list[str]:
    # TODO: pagination
    ...


@app.get("/v1/proj/{proj}/app/{app}", tags=["api"])
async def list_applications(
    proj: str, app: str, uid: Annotated[str, Depends(get_uid_by_api_key)]
) -> list[str]:
    # TODO: pagination
    ...


@app.get("/v1/proj/{proj}/app/{app}/ver/{ver}", tags=["api"])
async def describe_application(
    proj: str,
    app: str,
    uid: Annotated[str, Depends(get_uid_by_api_key)],
    ver: str,
) -> str:
    ...


@app.get("/v1/proj/{proj}/app/{app}/ver/{ver}/func", tags=["api"])
async def list_functions(
    uid: Annotated[str, Depends(get_uid_by_api_key)],
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
    uid: Annotated[str, Depends(get_uid_by_api_key)],
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
    uid: Annotated[str, Depends(get_uid_by_api_key)],
) -> str:
    # TODO: resolve `ver` of `"latest"` to docker image hash
    config = get_config()
    with DaprClient() as client:
        job = Job(
            created_by=uid,
            app=app,
            func=func,
            ver=ver,
            payload=payload,
        )
        client.save_state(
            config.job_store,
            job.id,
            job.json(),
        )
        client.publish_event(
            config.job_channel,
            f"{proj}.{app}.{ver}",
            job.json(),
            data_content_type="application/json",
        )
        client.publish_event(
            config.job_event_channel,
            JobStatusEnum.starting,
            JobEvent(job_id=job.id, status=JobStatusEnum.starting).json(),
            data_content_type="application/json",
        )
        return job.id


#####


@app.get("/v1/job/{job_id}", tags=["api"])
async def describe_job(
    uid: Annotated[str, Depends(get_uid_by_api_key)], job_id: str
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
                    status_code=status.HTTP_401_UNAUTHORIZED,
                    detail=f"Job[{job_id}] is not created by {uid}",
                )
        else:
            raise HTTPException(status_code=404, detail=f"Job[{job_id}] not found")


@app.get("/v1/job/{job_id}/result", tags=["api"])
async def get_job_result(uid: Annotated[str, Depends(get_uid_by_api_key)], job_id: str):
    config = get_config()
    with DaprClient() as client:
        res = client.get_state(config.job_result_store, job_id)
        if res.data:
            # TODO: make sure the result is create by `uid`
            return res.json()  # ??? plain text or json?
        else:
            raise HTTPException(
                status_code=404, detail=f"Job[{job_id}] result not found"
            )


@app.get("/v1/job/{job_id}/events", tags=["api"])
async def get_job_events(uid: Annotated[str, Depends(get_uid_by_api_key)], job_id: str):
    config = get_config()
    with DaprClient() as client:
        query = {"filter": {"EQ": {"job_id": job_id}}, "sort": [{"key": "created_at"}]}
        resp = client.query_state(config.job_event_store, query=json.dumps(query))
        return [JobEvent.parse_raw(r.value) for r in resp.results]


@app.delete("/v1/job/{job_id}", tags=["api"])
async def cancel_job(job_id: str, uid: Annotated[str, Depends(get_uid_by_api_key)]):
    ...


#####


@app.get("/v1/key", tags=["account"])
async def get_secret_keys(
    uid: Annotated[str, Depends(get_uid_from_jwt_token)]
) -> list[JugsawApiKey]:
    return get_api_keys_by_uid(uid)


@app.patch("/v1/key/api/{key_name}", tags=["account"])
@app.post("/v1/key/api/{key_name}", tags=["account"])
async def create_api_key(
    uid: Annotated[str, Depends(get_uid_from_jwt_token)],
    key_name: str,
) -> JugsawApiKey:
    return try_create_api_key(uid, key_name)


@app.delete("/v1/key/api/{key_name}", tags=["account"])
async def delete_api_key(
    uid: Annotated[str, Depends(get_uid_from_jwt_token)],
    key_name: str,
):
    delete_api_key_by_uid_name(uid, key_name)


@app.patch("/v1/key/reg/{key_name}", tags=["account"])
@app.post("/v1/key/reg/{key_name}", tags=["account"])
async def create_registry_key(
    user: Annotated[User, Depends(get_user_from_jwt_token)],
    key_name: str,
) -> JugsawApiKey:
    return try_create_registry_key(user, key_name)


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
async def ping_api(uid: Annotated[str, Depends(get_uid_by_api_key)]) -> str:
    return "pong"


@app.get("/v1/ping/key", tags=["ping"])
async def ping_key(uid: Annotated[str, Depends(get_uid_from_jwt_token)]) -> str:
    return "pong"


#####
@app.get("/dapr/subscribe")
async def subscribe() -> list[dict[str, str]]:
    return []
