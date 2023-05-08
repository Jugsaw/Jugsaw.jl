from enum import Enum
from functools import cache
from typing import Literal, Union
from typing_extensions import Annotated
from fastapi import FastAPI, Request
from dapr.clients import DaprClient
from pydantic import BaseModel, BaseSettings, Field
from uuid import uuid4
from time import time

app = FastAPI()


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
    signature: str
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


@app.post("/v1/app/{application}/{function}")
async def call(
    request: Request,
    application: str,
    function: str,
    version: str = "latest",
    signature: str = "",
) -> JobStatus:
    config = get_config()
    job = Job(
        created_by="annoymous",  # FIXME: get user_id from token
        application=application,
        function=function,
        version=version,
        signature=signature,
        data=await request.body(),
    )
    with DaprClient() as client:
        client.publish_event(
            config.job_channel, JobStatusEnum.starting, data=job.json()
        )
    return JobStatus(id=job.id)


@app.get("/v1/job/{job_id}")
async def get_job_status(job_id: str) -> JobStatus:
    ...


@app.get("/ping")
async def ping():
    return "pong"
