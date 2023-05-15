from functools import cache
from pydantic import BaseSettings


class Config(BaseSettings):
    # topics by `proj.app`
    job_channel: str = "jobs"

    # in-memory cache
    job_store: str = "job-store"
    job_key_format: str = "JUGSAW-JOB-STATUS:{job_id}"

    # persistent storage (s3)
    job_result_store: str = "job-result-store"
    job_result_key_format: str = "JUGSAW-JOB-RESULT:{job_id}"

    # RDB
    secret_store: str = "secret-store"


@cache
def get_config() -> Config:
    return Config()
