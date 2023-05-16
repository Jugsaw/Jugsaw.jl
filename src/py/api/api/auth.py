from time import time
import secrets
from jose import jwt, JWTError
from pydantic import BaseModel, Field
from time import time
from fastapi.security import HTTPBearer, APIKeyHeader, HTTPAuthorizationCredentials
from fastapi import Depends, HTTPException, status
from typing import Annotated, Optional
from dapr.clients import DaprClient

from .config import get_config

BEARER = HTTPBearer()


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


class JugsawApiKey(BaseModel):
    name: str = "default"
    value: str = Field(default_factory=secrets.token_urlsafe)
    created_at: float = Field(default_factory=time)


class JugsawApiKeys(BaseModel):
    keys: dict[str, JugsawApiKey] = {}


UID2API_KEY_FORMAT = "JUGSAW-UID-TO-API-KEY:{uid}"
API_KEY2UID_FORMAT = "JUGSAW-API-KEY-TO-UID:{key}"

API_KEY_HEADER = APIKeyHeader(name="JUGSAW-API-KEY")


def get_uid_from_api_key(
    key: Annotated[HTTPAuthorizationCredentials, Depends(API_KEY_HEADER)]
) -> str:
    config = get_config()
    with DaprClient() as client:
        resp = client.get_state(config.secret_store, API_KEY2UID_FORMAT.format(key=key))
        if resp.data:
            return resp.text()
        else:
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="Invalid JUGSAW-API-KEY",
            )


def get_api_keys_from_uid(uid: str) -> tuple[JugsawApiKeys, Optional[str]]:
    config = get_config()
    with DaprClient() as client:
        resp = client.get_state(config.secret_store, UID2API_KEY_FORMAT.format(uid=uid))
        if resp.data:
            api_key = JugsawApiKeys.parse_raw(resp.data)
            return api_key, resp.etag
        else:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="User not found",
            )


def try_delete_api_key(uid: str, key_name: str):
    config = get_config()
    with DaprClient() as client:
        existing_keys, etag = get_api_keys_from_uid(uid)
        if key_name in existing_keys.keys:
            del existing_keys.keys[key_name]
            client.save_state(
                config.secret_store,
                UID2API_KEY_FORMAT.format(uid=uid),
                existing_keys.json(),
                etag,
            )
        else:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail=f"API KEY [{key_name}] not found",
            )


def try_create_api_key(uid: str, key_name: str) -> JugsawApiKey:
    config = get_config()
    with DaprClient() as client:
        try:
            existing_keys, etag = get_api_keys_from_uid(uid)
            if key_name in existing_keys.keys:
                # 1. delete old apikey2uid mapping
                client.delete_state(
                    config.secret_store,
                    API_KEY2UID_FORMAT.format(key=existing_keys.keys[key_name]),
                )

            # 2. create a new api key
            new_key = JugsawApiKey(name=key_name)
            existing_keys.keys[key_name] = new_key
            client.save_state(
                config.secret_store,
                UID2API_KEY_FORMAT.format(uid=uid),
                existing_keys.json(),
                etag,
            )

            # 3. associate newkey2uid mapping
            client.save_state(
                config.secret_store,
                API_KEY2UID_FORMAT.format(key=new_key.value),
                uid,
            )

            return new_key
        except HTTPException:
            key = JugsawApiKey(name=key_name)
            keys = JugsawApiKeys(keys={key_name: key})
            client.save_state(
                config.secret_store, UID2API_KEY_FORMAT.format(uid=uid), keys.json()
            )
            client.save_state(
                config.secret_store, API_KEY2UID_FORMAT.format(key=key.value), uid
            )

            return key
