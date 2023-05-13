from functools import cache
from pydantic import BaseSettings


class Config(BaseSettings):
    job_channel: str = "jobs"
    job_status_store: str = "jobstatus"
    job_result_store: str = "jobresult"
    api_key_store: str = "apikey"

    github_jugsaw_client_id: str = "086ad58813c1d1e1354a"


@cache
def get_config() -> Config:
    return Config()
