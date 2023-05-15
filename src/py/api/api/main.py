from typing import Any
from typing_extensions import Annotated
from fastapi import Depends, FastAPI, HTTPException, Request, status
from dapr.clients import DaprClient
from pydantic import BaseModel, parse_raw_as

from .auth import (
    JugsawApiKey,
    JugsawApiKeys,
    get_api_keys_from_uid,
    get_uid_from_api_key,
    get_uid_from_github_token,
    try_create_api_key,
    try_delete_api_key,
)
from .job import Job, JobEvent, JobStatus, JobStatusEnum, Payload
from .config import get_config


app = FastAPI()

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
        job = Job(
            created_by=uid,
            app=app,
            func=func,
            ver=ver,
            payload=payload,
        )
        job_status = JobStatus(job=job)
        client.save_state(
            config.job_store,
            config.job_key_format.format(job_id=job.id),
            job_status.json(),
        )
        client.publish_event(config.job_channel, f"{proj}.{app}.{ver}", job.json())
        client.publish_event(
            config.job_channel,
            JobStatusEnum.starting,
            JobEvent(id=job.id, status=JobStatusEnum.starting).json(),
        )
        return job.id


#####


@app.get("/v1/job/{job_id}", tags=["api"])
async def describe_job(
    uid: Annotated[str, Depends(get_uid_from_api_key)], job_id: str
) -> JobStatus:
    config = get_config()
    with DaprClient() as client:
        res = client.get_state(
            config.job_store, config.job_key_format.format(job_id=job_id)
        )
        if res.data:
            job_status = JobStatus.parse_raw(res.data)
            # TODO: make sure the job is created by `uid`
            return job_status
        else:
            raise HTTPException(status_code=404, detail=f"Job[{job_id}] not found")


@app.get("/v1/job/{job_id}/result", tags=["api"])
async def get_job_result(
    uid: Annotated[str, Depends(get_uid_from_api_key)], job_id: str
):
    config = get_config()
    with DaprClient() as client:
        res = client.get_state(
            config.job_result_store, config.job_result_key_format.format(job_id=job_id)
        )
        if res.data:
            # TODO: make sure the result is create by `uid`
            return res.json()  # ??? plain text or json?
        else:
            raise HTTPException(
                status_code=404, detail=f"Job[{job_id}] result not found"
            )


@app.delete("/v1/job/{job_id}", tags=["api"])
async def cancel_job(job_id: str, uid: Annotated[str, Depends(get_uid_from_api_key)]):
    ...


#####


@app.get("/v1/key/api", tags=["account"])
async def get_api_key(
    uid: Annotated[str, Depends(get_uid_from_github_token)]
) -> JugsawApiKeys:
    keys, _ = get_api_keys_from_uid(uid)
    return keys


@app.patch("/v1/key/api/{key_name}", tags=["account"])
@app.post("/v1/key/api/{key_name}", tags=["account"])
async def create_api_key(
    uid: Annotated[str, Depends(get_uid_from_github_token)],
    key_name: str = "default",
) -> JugsawApiKey:
    return try_create_api_key(uid, key_name)


@app.delete("/v1/key/api/{key_name}", tags=["account"])
async def delete_api_key(
    uid: Annotated[str, Depends(get_uid_from_github_token)],
    key_name: str = "default",
):
    return try_delete_api_key(uid, key_name)


#####


@app.get("/v1/jobs", tags=["account"])
async def get_user_jobs(
    uid: Annotated[str, Depends(get_uid_from_github_token)]
) -> list[str]:
    ...


@app.get("/v1/apps", tags=["account"])
async def get_user_apps(
    uid: Annotated[str, Depends(get_uid_from_github_token)]
) -> list[str]:
    ...


#####


@app.get("/v1/ping/api", tags=["ping"])
async def ping_api(uid: Annotated[str, Depends(get_uid_from_api_key)]) -> str:
    return "pong"


@app.get("/v1/ping/key", tags=["ping"])
async def ping_key(uid: Annotated[str, Depends(get_uid_from_github_token)]) -> str:
    return "pong"


#####
@app.get("/dapr/subscribe")
async def subscribe() -> list[dict[str, str]]:
    return []
