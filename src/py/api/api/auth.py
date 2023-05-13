import aiohttp
from pydantic import BaseModel
from fastapi.security import HTTPBearer, APIKeyHeader, HTTPAuthorizationCredentials
from fastapi import Depends, HTTPException, status
from typing import Annotated
from dapr.clients import DaprClient

from .config import get_config

BEARER = HTTPBearer()


# https://docs.github.com/en/rest/users/users?apiVersion=2022-11-28#get-the-authenticated-user
async def get_user_from_token(
    token: Annotated[HTTPAuthorizationCredentials, Depends(BEARER)]
) -> str:
    async with aiohttp.ClientSession(
        headers={"Authorization": f"Bearer {token}"}
    ) as session:
        async with session.get("https://api.github.com/user") as response:
            resp = await response.json()
            return resp["login"]


#####


API_KEY_HEADER = APIKeyHeader(name="JUGSAW-API-KEY")


def get_user_from_api_key(
    token: Annotated[HTTPAuthorizationCredentials, Depends(API_KEY_HEADER)]
) -> str:
    config = get_config()
    with DaprClient() as client:
        resp = client.get_state(config.api_key_store, f"JUGSAW-API-KEY2USER:{token}")
        if resp.data:
            return resp.text()
        else:
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="Invalid JUGSAW-API-KEY",
            )


class JugsawApiKey(BaseModel):
    key: str


def get_api_key_from_user(user: str) -> str:
    config = get_config()
    with DaprClient() as client:
        resp = client.get_state(config.api_key_store, f"USER2JUGSAW-API-KEY:{user}")
        if resp.data:
            api_key = JugsawApiKey.parse_raw(resp.data)
            return api_key.key
        else:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="User not found",
            )
