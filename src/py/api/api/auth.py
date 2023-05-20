import json
from time import time
import aiohttp
from jose import jwt, JWTError
from pydantic import BaseModel
from time import time
from fastapi.security import HTTPBearer, APIKeyHeader, HTTPAuthorizationCredentials
from fastapi import Depends, HTTPException, status
from typing import Annotated, Optional
from dapr.clients import DaprClient

from .config import get_config
from .harbor import create_project, create_robot

BEARER = HTTPBearer()


class UserBasic(BaseModel):
    id: str
    login: str


class User(BaseModel):
    basic: UserBasic

    creation_time: str
    secret: str


def get_user_by_jwt_token(
    token: Annotated[HTTPAuthorizationCredentials, Depends(BEARER)]
) -> UserBasic:
    credentials_exception = HTTPException(
        status_code=status.HTTP_401_UNAUTHORIZED,
        detail="Could not validate credentials",
        headers={"WWW-Authenticate": "Bearer"},
    )

    config = get_config()
    try:
        payload = jwt.decode(token.credentials, config.jwt_secret, algorithms=["HS256"])
        uid = payload.get("id")
        login = payload.get("login")
        exp = payload.get("exp")
        if uid is None or login is None or exp is None or exp < time():
            raise credentials_exception
        return UserBasic(id=uid, login=login)
    except JWTError:
        raise credentials_exception


def get_uid_by_jwt_token(user: UserBasic = Depends(get_user_by_jwt_token)) -> str:
    return user.id


def get_user(uid: str) -> Optional[User]:
    config = get_config()
    with DaprClient() as client:
        resp = client.get_state(config.user_store, uid)
        if resp.data:
            return User.parse_raw(resp.data)


async def try_get_secret(client: aiohttp.ClientSession, u: UserBasic) -> str:
    """
    A new one will be created if no secret found.
    """
    if user := get_user(u.id):
        return user.secret
    else:
        await create_project(client, u.login)
        robot_resp = await create_robot(client, u.login)
        user = User(
            basic=u, creation_time=robot_resp.creation_time, secret=robot_resp.secret
        )
        with DaprClient() as dapr_client:
            config = get_config()
            dapr_client.save_state(
                config.user_store,
                u.id,
                user.json(),
                state_metadata={"contentType": "application/json"},
            )
        return user.secret


#####

API_KEY_HEADER = APIKeyHeader(name="JUGSAW-API-KEY", scheme_name="Jugsaw API Key")


def get_user_by_api_key(secret: Annotated[str, Depends(API_KEY_HEADER)]) -> UserBasic:
    with DaprClient() as client:
        config = get_config()
        query = {"filter": {"EQ": {"secret": secret}}}
        resp = client.query_state(config.user_store, json.dumps(query))
        if len(resp.results) == 1:
            user = User.parse_raw(resp.results[0].value)
            return user.basic
        else:
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="Invalid JUGSAW-API-KEY!",
            )


def get_uid_by_api_key(user: UserBasic = Depends(get_user_by_api_key)):
    return user.id
