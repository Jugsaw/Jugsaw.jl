import json
from enum import Enum
from uuid import uuid4
from pydantic import BaseModel, Field
from typing import Any, Optional
from dapr.clients import DaprClient

from .utils import now_iso_z
from .config import get_config


class Payload(BaseModel):
    args: list[Any]
    kwargs: dict[str, Any]


class JobStatusEnum(str, Enum):
    starting = "starting"
    pending = "pending"
    processing = "processing"
    succeeded = "succeeded"
    failed = "failed"
    canceled = "canceled"


class JobEvent(BaseModel):
    id: str = Field(default_factory=lambda: str(uuid4()))
    job_id: str
    status: JobStatusEnum
    created_at: str = Field(default_factory=now_iso_z)
    description: str = ""


class Job(BaseModel):
    id: str = Field(default_factory=lambda: str(uuid4()))
    created_at: str = Field(default_factory=now_iso_z)
    created_by: str

    app: str
    func: str
    ver: str
    payload: Payload


#####


def submit_job(
    proj: str, app: str, ver: str, func: str, payload: Payload, uid: str
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
        client.save_state(
            config.job_store,
            job.id,
            job.json(),
            state_metadata={"contentType": "application/json"},
        )
        client.publish_event(
            config.job_channel,
            f"{proj}-{app}-{ver}",
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


def describe_job(uid: str, job_id: str) -> Optional[Job]:
    config = get_config()
    with DaprClient() as client:
        res = client.get_state(config.job_store, job_id)
        if res.data:
            job = Job.parse_raw(res.data)
            if job.created_by == uid:
                return job


def get_job_result(uid: str, job_id: str):
    config = get_config()
    with DaprClient() as client:
        res = client.get_state(config.job_result_store, job_id)
        if res.data:
            # TODO: make sure the result is create by `uid`
            return res.json()  # ??? plain text or json?


def get_job_events(uid: str, job_id: str) -> list[JobEvent]:
    config = get_config()
    with DaprClient() as client:
        query = {"filter": {"EQ": {"job_id": job_id}}, "sort": [{"key": "created_at"}]}
        resp = client.query_state(config.job_event_store, query=json.dumps(query))
        return [JobEvent.parse_raw(r.value) for r in resp.results]


def list_jobs(uid: str) -> list[Job]:
    config = get_config()
    with DaprClient() as client:
        query = {"filter": {"EQ": {"created_by": uid}}, "sort": [{"key": "created_at"}]}
        resp = client.query_state(config.job_store, query=json.dumps(query))
        return [Job.parse_raw(r.value) for r in resp.results]
