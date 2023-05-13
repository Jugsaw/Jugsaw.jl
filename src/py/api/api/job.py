from enum import Enum
from uuid import uuid4
from pydantic import BaseModel, Field
from time import time


class Job(BaseModel):
    id: str = Field(default_factory=lambda: str(uuid4()))
    created_at: float = Field(default_factory=time)
    created_by: str

    app: str
    func: str
    ver: str
    data: bytes


class JobStatusEnum(str, Enum):
    starting = "starting"
    pending = "pending"
    processing = "processing"
    succeeded = "succeeded"
    failed = "failed"
    canceled = "canceled"


class JobEvent(BaseModel):
    id: str
    status: str
    timestamp: float = Field(default_factory=time)
    description: str = ""


class JobStatus(BaseModel):
    id: str
    events: list[JobEvent] = []
