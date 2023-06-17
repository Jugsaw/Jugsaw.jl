from functools import cache
from pydantic import BaseSettings


class Config(BaseSettings):
    # pubsub
    job_channel: str = "jugsaw-job-pubsub"
    job_event_channel: str = "jugsaw-job-event-pubsub"  # AWS SNS/SQS ?

    # storage (with query support)
    job_store: str = "jugsaw-job-store"
    job_event_store: str = "jugsaw-job-event-store"
    user_store: str = "jugsaw-user-store"

    # general storage
    job_result_store: str = "jugsaw-job-result-store"

    # auth
    jwt_secret: str = "SET ME THROUGH ENVIRONMENT VARIABLE"
    registry_base_url: str = "https://harbor.jugsaw.co"
    registry_admin_username: str = "SET ME THROUGH ENVIRONMENT VARIABLE"
    registry_admin_password: str = "SET ME THROUGH ENVIRONMENT VARIABLE"
    registry_webhook_token: str = "SET ME THROUGH ENVIRONMENT VARIABLE"


@cache
def get_config() -> Config:
    return Config()
