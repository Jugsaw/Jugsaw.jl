import secrets
from enum import Enum
import json
from time import time
from jose import jwt, JWTError
from pydantic import BaseModel, Field
from time import time
from fastapi.security import HTTPBearer, APIKeyHeader, HTTPAuthorizationCredentials
from fastapi import Depends, HTTPException, status
from typing import Annotated, Optional
from dapr.clients import DaprClient

from .config import get_config
from .utils import now_iso_z, gen_secret_value

BEARER = HTTPBearer()


class User(BaseModel):
    id: str
    login: str


async def get_user_from_jwt_token(
    token: Annotated[HTTPAuthorizationCredentials, Depends(BEARER)]
) -> User:
    credentials_exception = HTTPException(
        status_code=status.HTTP_401_UNAUTHORIZED,
        detail="Could not validate credentials",
        headers={"WWW-Authenticate": "Bearer"},
    )

    config = get_config()
    try:
        payload = jwt.decode(token.credentials, config.jwt_secret, algorithms=["HS256"])
        uid = payload.get("id")
        uname = payload.get("login")
        exp = payload.get("exp")
        if uid is None or uname is None or exp is None or exp < time():
            raise credentials_exception
        return User(id=uid, login=uname)
    except JWTError:
        raise credentials_exception


async def get_uid_from_jwt_token(user: User = Depends(get_user_from_jwt_token)) -> str:
    return user.id


#####
# Keys
#####


class JugsawKeyBase(BaseModel):
    name: str
    value: str = Field(default_factory=gen_secret_value)
    created_at: str = Field(default_factory=now_iso_z)

    @property
    def key(self) -> str:
        return f"api-{self.value}"


class JugsawApiKey(JugsawKeyBase):
    created_by: str

    @staticmethod
    def check(key: str):
        if not key.startswith("api-"):
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Invalid JUGSAW-API-KEY, a valid key should starts with `api-`.",
            )


API_KEY_HEADER = APIKeyHeader(name="JUGSAW-API-KEY", scheme_name="Jugsaw API Key")


def get_uid_by_api_key(
    api_key_header: Annotated[HTTPAuthorizationCredentials, Depends(API_KEY_HEADER)]
) -> str:
    s_key = api_key_header.credentials
    JugsawApiKey.check(s_key)
    config = get_config()
    with DaprClient() as client:
        resp = client.get_state(config.api_key_store, s_key)
        if resp.data:
            key = JugsawApiKey.parse_raw(resp.data)
            return key.created_by
        else:
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="Invalid JUGSAW-API-KEY!",
            )


def _get_api_key(uid: str, key_name: str) -> JugsawApiKey:
    config = get_config()
    with DaprClient() as client:
        query = {
            "filter": {
                "AND": [
                    {"EQ": {"created_by": uid}},
                    {"EQ": {"name": key_name}},
                ]
            }
        }
        resp = client.query_state(config.api_key_store, json.dumps(query))

        if len(resp.results) == 0:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail=f"Key name [{key_name}] not found!",
            )
        else:
            assert len(resp.results) == 0, f"Duplicate key name [{key_name}] found"
            return JugsawApiKey.parse_raw(resp.results[0].value)


def get_api_keys_by_uid(uid: str) -> list[JugsawApiKey]:
    config = get_config()
    with DaprClient() as client:
        query = {"filter": {"EQ": {"created_by": uid}}}
        resp = client.query_state(config.api_key_store, json.dumps(query))
        return [JugsawApiKey.parse_raw(r.value) for r in resp.results]


def delete_api_key_by_uid_name(uid: str, key_name: str):
    key = _get_api_key(uid, key_name)
    config = get_config()
    with DaprClient() as client:
        client.delete_state(config.api_key_store, key.key)


def try_create_api_key(uid: str, key_name: str) -> JugsawApiKey:
    """
    If `key_name` already exists, its value will be rotated.
    """
    config = get_config()
    with DaprClient() as client:
        try:
            # rotate
            key = _get_api_key(uid, key_name)
            key.value = gen_secret_value()
            key.created_at = now_iso_z()
        except HTTPException:
            # create a new one
            key = JugsawApiKey(name=key_name, created_by=uid)

        client.save_state(config.api_key_store, key.key, key.json())
        return key


#####


def try_create_registry_key(user: User, key_name: str) -> JugsawApiKey:
    """
    If `key_name` already exists, its value will be rotated.
    """
    config = get_config()
    with DaprClient() as client:
        try:
            key = _get_api_key(user.id, JugsawSecretEnum.reg, key_name)
            key.value = gen_secret_value()
            key.created_at = now_iso_z()
        except HTTPException:
            key = JugsawApiKey(
                name=key_name, kind=JugsawSecretEnum.reg, created_by=user.id
            )
