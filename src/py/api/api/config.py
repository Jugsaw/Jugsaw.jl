from typing import Optional
from functools import cache
from pydantic import BaseSettings


class Config(BaseSettings):
    # pubsub
    job_channel: str = "job"

    # storage
    job_result_store: str = "job-result"
    job_store: str = "job"
    user_store: str = "user"
    api_store: str = "api"

    # api auth
    jwt_secret: str = "SET ME THROUGH ENVIRONMENT VARIABLE"

    # dapr auth
    dapr_api_token: Optional[str] = None  # SET ME THROUGH ENVIRONMENT VARIABLE

    # registry auth
    registry_base_url: str = "https://harbor.jugsaw.co/api/v2.0"
    registry_admin_username: str = "api"
    registry_admin_password: str = "SET ME THROUGH ENVIRONMENT VARIABLE"


@cache
def get_config() -> Config:
    return Config()
