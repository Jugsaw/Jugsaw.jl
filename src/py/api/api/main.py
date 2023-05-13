from typing_extensions import Annotated
from fastapi import Depends, FastAPI, HTTPException, Request
from dapr.clients import DaprClient

from .auth import JugsawApiKey, get_user_from_api_key, get_user_from_token
from .job import Job, JobStatus, JobStatusEnum
from .config import get_config

app = FastAPI()

#####


@app.get("/v1/app", tags=["api"])
async def list_apps(user: Annotated[str, Depends(get_user_from_api_key)]) -> list[str]:
    # TODO: pagination
    ...


@app.get("/v1/app/{app}", tags=["api"])
async def list_app_versions(
    user: Annotated[str, Depends(get_user_from_api_key)], app: str
) -> list[str]:
    # TODO: pagination
    ...


@app.post("/v1/app/{app}", tags=["api"])
async def create_app(
    user: Annotated[str, Depends(get_user_from_api_key)], app: str
) -> list[str]:
    # TODO: pagination
    ...


@app.get("/v1/app/{app}/{app_ver}", tags=["api"])
async def describe_app(
    user: Annotated[str, Depends(get_user_from_api_key)],
    app: str,
    app_ver: str = "latest",
) -> str:
    ...


@app.delete("/v1/app/{app}/{app_ver}", tags=["api"])
async def delete_app(
    user: Annotated[str, Depends(get_user_from_api_key)],
    app: str,
    app_ver: str = "latest",
) -> str:
    ...


@app.get("/v1/app/{app}/{app_ver}/func", tags=["api"])
async def list_functions(
    user: Annotated[str, Depends(get_user_from_api_key)],
    app: str,
    app_ver: str = "latest",
) -> str:
    ...


@app.get("/v1/app/{app}/{app_ver}/func/{func}", tags=["api"])
async def get_function_schema(
    user: Annotated[str, Depends(get_user_from_api_key)],
    app: str,
    func: str,
    app_ver: str = "latest",
) -> str:
    ...


@app.post("/v1/app/{app}/{app_ver}/func/{function}", tags=["api"])
async def submit_job(
    user: Annotated[str, Depends(get_user_from_api_key)],
    request: Request,
    app: str,
    func: str,
    ver: str = "latest",
) -> JobStatus:
    config = get_config()
    job = Job(
        created_by=user,
        app=app,
        func=func,
        ver=ver,
        data=await request.body(),
    )
    with DaprClient() as client:
        client.publish_event(
            config.job_channel, JobStatusEnum.starting, data=job.json()
        )
    return JobStatus(id=job.id)


@app.get("/v1/job/{job_id}", tags=["api"])
async def get_job_status(
    user: Annotated[str, Depends(get_user_from_api_key)], job_id: str
) -> JobStatus:
    config = get_config()
    with DaprClient() as client:
        res = client.get_state(config.job_status_store, job_id)
        if res.data:
            job_status = JobStatus.parse_raw(res.data)
            return job_status
        else:
            raise HTTPException(status_code=404, detail=f"Job[{job_id}] not found")


@app.get("/v1/job/{job_id}/result", tags=["api"])
async def get_job_result(
    user: Annotated[str, Depends(get_user_from_api_key)], job_id: str
):
    config = get_config()
    with DaprClient() as client:
        res = client.get_state(config.job_result_store, job_id)
        return res.json()


@app.delete("/v1/job/{job_id}", tags=["api"])
async def cancel_job(
    user: Annotated[str, Depends(get_user_from_api_key)], job_id: str
) -> JobStatus:
    ...


@app.get("/v1/ping/api", tags=["api", "ping"])
async def ping_api(user: Annotated[str, Depends(get_user_from_api_key)]) -> str:
    return "pong"


#####


@app.get("/v1/user/key", tags=["account"])
async def get_api_key(
    user: Annotated[str, Depends(get_user_from_token)]
) -> JugsawApiKey:
    ...


@app.post("/v1/user/key", tags=["account"])
async def create_api_key(
    user: Annotated[str, Depends(get_user_from_token)]
) -> JugsawApiKey:
    ...


@app.patch("/v1/user/key", tags=["account"])
async def revoke_api_key(
    user: Annotated[str, Depends(get_user_from_token)]
) -> JugsawApiKey:
    ...


@app.get("/v1/ping/auth", tags=["account", "ping"])
async def ping_key(user: Annotated[str, Depends(get_user_from_token)]) -> str:
    return "pong"


#####


@app.get("/v1/user/jobs", tags=["account"])
async def get_user_jobs(
    user: Annotated[str, Depends(get_user_from_token)]
) -> list[str]:
    ...


@app.get("/v1/user/apps", tags=["account"])
async def get_user_apps(
    user: Annotated[str, Depends(get_user_from_token)]
) -> list[str]:
    ...
