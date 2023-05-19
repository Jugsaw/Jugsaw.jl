from functools import cache
from pydantic import BaseSettings


class Config(BaseSettings):
    # pubsub
    job_channel: str = "jugsaw-job-pubsub"
    job_event_channel: str = "jugsaw-job-event-pubsub"  # AWS SNS/SQS

    # storage
    job_store: str = "jugsaw-job-store"
    job_event_store: str = "jugsaw-job-event-store"
    job_result_store: str = "jugaw-job-result-store"
    api_key_store: str = "jugsaw-secret-store"

    jwt_secret: str = "SET ME THROUGH ENVIRONMENT VARIABLE"


@cache
def get_config() -> Config:
    return Config()
