from enum import Enum
from functools import cache
from typing import Literal, Union
from typing_extensions import Annotated
from fastapi import Depends, FastAPI, Request, HTTPException, status
from fastapi.security import HTTPBearer, APIKeyHeader, HTTPAuthorizationCredentials
from dapr.clients import DaprClient
from pydantic import BaseModel, BaseSettings, Field
from uuid import uuid4
from time import time

app = FastAPI()

BEARER = HTTPBearer()


def get_user_from_token(
    token: Annotated[HTTPAuthorizationCredentials, Depends(BEARER)]
):
    return "abc"


API_KEY_HEADER = APIKeyHeader(name="JUGSAW-API-KEY")


def get_user_from_api_key(
    token: Annotated[HTTPAuthorizationCredentials, Depends(API_KEY_HEADER)]
):
    return "xx"


class Config(BaseSettings):
    job_channel: str = "job"


@cache
def get_config() -> Config:
    return Config()


class Job(BaseModel):
    id: str = Field(default_factory=lambda: str(uuid4()))
    created_at: float = Field(default_factory=time)
    created_by: str

    application: str
    function: str
    version: str
    data: bytes


class JobStatusEnum(str, Enum):
    starting = "starting"
    processing = "processing"
    succeeded = "succeeded"
    failed = "failed"
    canceled = "canceled"


class JobEventBase(BaseModel):
    job_id: str
    status: str
    time: float = Field(default_factory=time)


class JobStartingEvent(JobEventBase):
    status: Literal[JobStatusEnum.starting] = JobStatusEnum.starting


class JobProcessingEvent(JobEventBase):
    status: Literal[JobStatusEnum.processing] = JobStatusEnum.processing


class JobSucceededEvent(JobEventBase):
    status: Literal[JobStatusEnum.succeeded] = JobStatusEnum.succeeded


class JobFailedEvent(JobEventBase):
    status: Literal[JobStatusEnum.failed] = JobStatusEnum.failed


class JobCanceledEvent(JobEventBase):
    status: Literal[JobStatusEnum.canceled] = JobStatusEnum.canceled


JobEvent = Annotated[
    Union[
        JobStartingEvent,
        JobProcessingEvent,
        JobSucceededEvent,
        JobFailedEvent,
        JobCanceledEvent,
    ],
    Field(discriminator="status"),
]


class JobStatus(BaseModel):
    id: str
    events: list[JobEvent] = []


class JugsawApiKey(BaseModel):
    key: str


class Application(BaseModel):
    name: str
    version: str


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
        application=app,
        function=func,
        version=ver,
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
    ...


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
