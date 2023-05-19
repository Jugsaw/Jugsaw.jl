from enum import Enum
from uuid import uuid4
from pydantic import BaseModel, Field
from typing import Any

from .utils import now_iso_z


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
    updated_at: str = ""
    created_by: str

    app: str
    func: str
    ver: str
    payload: Payload
