import json
from enum import Enum
import secrets
from jose import jwt, JWTError
from pydantic import BaseModel, Field
from time import time
from datetime import datetime, timezone
from fastapi.security import HTTPBearer, APIKeyHeader, HTTPAuthorizationCredentials
from fastapi import Depends, HTTPException, status
from typing import Annotated
from dapr.clients import DaprClient
import aiohttp

from .config import get_config

BEARER = HTTPBearer(scheme_name="Jugsaw JWT Token")


async def get_uid_from_jwt_token(
    token: Annotated[HTTPAuthorizationCredentials, Depends(BEARER)]
) -> str:
    credentials_exception = HTTPException(
        status_code=status.HTTP_401_UNAUTHORIZED,
        detail="Could not validate credentials",
        headers={"WWW-Authenticate": "Bearer"},
    )

    config = get_config()
    try:
        payload = jwt.decode(token.credentials, config.jwt_secret, algorithms=["HS256"])
        uid = payload.get("id")
        exp = payload.get("exp")
        if uid is None or exp is None or exp < time():
            raise credentials_exception
        return uid
    except JWTError:
        raise credentials_exception


#####


class ApiKey(BaseModel):
    name: str = "default"
    value: str = Field(default_factory=secrets.token_urlsafe)
    created_at: str = Field(
        default_factory=lambda: datetime.now(timezone.utc)
        .isoformat()
        .replace("+00:00", "Z")
    )
    created_by: str = ""


API_KEY_HEADER = APIKeyHeader(name="JUGSAW-API-KEY", scheme_name="Jugsaw API Key")


def get_uid_from_api_key(
    key: Annotated[HTTPAuthorizationCredentials, Depends(API_KEY_HEADER)]
) -> str:
    config = get_config()
    with DaprClient() as client:
        resp = client.get_state(config.secret_store, key.credentials)
        if resp.data:
            k = ApiKey.parse_raw(resp.data)
            return k.created_by
        else:
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="Invalid JUGSAW-API-KEY",
            )


def get_keys_by_uid(uid: str) -> list[ApiKey]:
    config = get_config()
    with DaprClient() as client:
        query = {"filter": {"EQ": {"created_by": uid}}}
        resp = client.query_state(config.secret_store, json.dumps(query))
        return [ApiKey.parse_raw(r.value) for r in resp.results]


def try_delete_key(uid: str, key_name: str):
    config = get_config()
    with DaprClient() as client:
        # 1. find keys
        query = {
            "filter": {"AND": [{"EQ": {"created_by": uid}}, {"EQ": {"name": key_name}}]}
        }
        resp = client.query_state(config.secret_store, json.dumps(query))
        # 2. delete
        for r in resp.results:
            client.delete_state(config.secret_store, r.key)


def try_create_api_key(uid: str, key_name: str) -> ApiKey:
    """
    If the `key_name` already exists, it'll be revoked.
    """
    try_delete_key(uid, key_name)

    config = get_config()
    with DaprClient() as client:
        key = ApiKey(
            name=key_name,
        )
        client.save_state(config.secret_store, key.value, key.json())
        return key


#####


# async def try_get_registry_key(user_name: str) -> str:
#     config = get_config()
#     auth = aiohttp.BasicAuth(
#         config.registry_admin_username, config.registry_admin_password
#     )
#     async with aiohttp.ClientSession(config.registry_endpoint, auth=auth) as client:
#         is_registered = await is_project_exists(client, user_name)


# async def is_project_exists(user_name: str) -> bool:
#     async with aiohttp.ClientSession("https://harbor.jugsaw.co", auth=auth) as client:
#         async with client.head("/projects", params={"project_name": user_name}) as resp:
#             return resp.status == 200
