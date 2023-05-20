from typing_extensions import Annotated
import aiohttp
from fastapi import Depends, FastAPI, HTTPException, status

from .auth import (
    UserBasic,
    get_uid_by_api_key,
    get_user_by_jwt_token,
    try_get_secret,
)
from . import job
from .job import Job, JobEvent, Payload
from .harbor import (
    HARBOR_CLIENT,
    list_artifacts,
    list_projects_names,
    list_repositories,
    resolve_artifact,
)


app = FastAPI(title="Jugsaw API")

#####


@app.get("/v1/proj", tags=["App"])
async def list_projects(
    client: Annotated[aiohttp.ClientSession, Depends(HARBOR_CLIENT)],
    uid: Annotated[str, Depends(get_uid_by_api_key)],
    page: int = 1,
    page_size: int = 10,
) -> list[str]:
    return await list_projects_names(client, page, page_size)


@app.get("/v1/proj/{proj}", tags=["App"])
async def describe_project(
    client: Annotated[aiohttp.ClientSession, Depends(HARBOR_CLIENT)],
    uid: Annotated[str, Depends(get_uid_by_api_key)],
    proj: str,
    page: int = 1,
    page_size: int = 10,
) -> list[str]:
    return await list_repositories(client, proj, page, page_size)


@app.get("/v1/proj/{proj}/app/{app}", tags=["App"])
async def list_applications(
    client: Annotated[aiohttp.ClientSession, Depends(HARBOR_CLIENT)],
    uid: Annotated[str, Depends(get_uid_by_api_key)],
    proj: str,
    app: str,
    page: int = 1,
    page_size: int = 10,
) -> list[str]:
    return await list_artifacts(client, proj, app, page, page_size)


@app.get("/v1/proj/{proj}/app/{app}/ver/{ver}", tags=["App"])
async def describe_application(
    proj: str,
    app: str,
    uid: Annotated[str, Depends(get_uid_by_api_key)],
    ver: str,
) -> str:
    ...


@app.get("/v1/proj/{proj}/app/{app}/ver/{ver}/func", tags=["App"])
async def list_functions(
    uid: Annotated[str, Depends(get_uid_by_api_key)],
    proj: str,
    app: str,
    ver: str,
) -> str:
    ...


@app.get("/v1/proj/{proj}/app/{app}/ver/{ver}/func/{func}", tags=["App"])
async def describe_function(
    proj: str,
    app: str,
    func: str,
    uid: Annotated[str, Depends(get_uid_by_api_key)],
    ver: str,
) -> str:
    ...


@app.post("/v1/proj/{proj}/app/{app}/ver/{ver}/func/{func}", tags=["App"])
async def submit_job(
    proj: str,
    app: str,
    ver: str,
    func: str,
    payload: Payload,
    uid: Annotated[str, Depends(get_uid_by_api_key)],
    client: Annotated[aiohttp.ClientSession, Depends(HARBOR_CLIENT)],
) -> str:
    # TODO: resolve func
    artifact = await resolve_artifact(client, proj, app, ver)
    if artifact is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"Unable to resolve the application[{proj}/{app}:{ver}]",
        )
    else:
        return job.submit_job(proj, app, artifact, func, payload, uid)


#####


@app.get("/v1/job", tags=["Job"])
def list_jobs(uid: Annotated[str, Depends(get_uid_by_api_key)]) -> list[Job]:
    return job.list_jobs(uid)


@app.get("/v1/job/{job_id}", tags=["Job"])
def describe_job(uid: Annotated[str, Depends(get_uid_by_api_key)], job_id: str) -> Job:
    res = job.describe_job(uid, job_id)
    if res is None:
        raise HTTPException(status_code=404, detail=f"Job[{job_id}] not found")
    else:
        return res


@app.get("/v1/job/{job_id}/result", tags=["Job"])
def get_job_result(uid: Annotated[str, Depends(get_uid_by_api_key)], job_id: str):
    res = job.get_job_result(uid, job_id)
    if res is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND, detail=f"Job[{job_id}] not found"
        )
    else:
        return res


@app.get("/v1/job/{job_id}/events", tags=["Job"])
def get_job_events(
    uid: Annotated[str, Depends(get_uid_by_api_key)], job_id: str
) -> list[JobEvent]:
    return job.get_job_events(uid, job_id)


#####


@app.get("/v1/key", tags=["Secret"])
async def get_secret(
    client: Annotated[aiohttp.ClientSession, Depends(HARBOR_CLIENT)],
    uid: Annotated[UserBasic, Depends(get_user_by_jwt_token)],
) -> str:
    return await try_get_secret(client, uid)


@app.get("/v1/key/ping", tags=["Secret"])
async def ping_key(
    user: Annotated[UserBasic, Depends(get_user_by_jwt_token)]
) -> UserBasic:
    return user


#####


@app.get("/dapr/subscribe", include_in_schema=False)
def subscribe():
    return []


#####


@app.on_event("startup")
async def startup():
    HARBOR_CLIENT.open()


@app.on_event("shutdown")
async def on_shutdown():
    await HARBOR_CLIENT.close()
