import aiohttp
from typing import Optional
from pydantic import BaseModel

from .config import get_config


class HarborClientSingleton:
    _client: Optional[aiohttp.ClientSession] = None

    def open(self):
        c = get_config()
        auth = aiohttp.BasicAuth(c.registry_admin_username, c.registry_admin_password)
        jar = aiohttp.DummyCookieJar()
        self._client = aiohttp.ClientSession(
            c.registry_base_url, auth=auth, cookie_jar=jar
        )

    async def close(self):
        if self._client:
            await self._client.close()
            self._client = None

    def __call__(self) -> aiohttp.ClientSession:
        assert self._client is not None
        return self._client


HARBOR_CLIENT = HarborClientSingleton()


async def create_project(client: aiohttp.ClientSession, name: str):
    async with client.post(
        "/api/v2.0/projects",
        json={
            "project_name": name,
            "public": False,
            "storage_limit": -1,
        },
    ) as resp:
        assert resp.status == 201


class CreateRobotResponse(BaseModel):
    secret: str
    creation_time: str
    id: int
    expires_at: int
    name: str


async def create_robot(
    client: aiohttp.ClientSession, project: str, name: str = "default"
) -> CreateRobotResponse:
    async with client.post(
        "/api/v2.0/robots",
        json={
            "name": name,
            "duration": -1,
            "disable": False,
            "level": "project",
            "permissions": [
                {
                    "namespace": project,
                    "kind": "project",
                    "access": [
                        {"resource": "repository", "action": "list"},
                        {"resource": "repository", "action": "pull"},
                        {"resource": "repository", "action": "push"},
                        {"resource": "repository", "action": "delete"},
                        {"resource": "artifact", "action": "read"},
                        {"resource": "artifact", "action": "list"},
                        {"resource": "artifact", "action": "delete"},
                        {"resource": "artifact-label", "action": "create"},
                        {"resource": "artifact-label", "action": "delete"},
                        {"resource": "tag", "action": "create"},
                        {"resource": "tag", "action": "delete"},
                        {"resource": "tag", "action": "list"},
                        {"resource": "scan", "action": "create"},
                        {"resource": "scan", "action": "stop"},
                    ],
                }
            ],
        },
    ) as resp:
        return CreateRobotResponse.parse_raw(await resp.read())


async def list_projects_names(
    client: aiohttp.ClientSession, page: int, page_size: int
) -> list[str]:
    config = get_config()
    async with client.get(
        "/api/v2.0/projects",
        params={
            "page": page,
            "page_size": page_size,
            "owner": config.registry_admin_username,
        },
    ) as resp:
        projects = await resp.json()
        return [p["name"] for p in projects]


async def list_repositories(
    client: aiohttp.ClientSession, project: str, page: int, page_size: int
) -> list[str]:
    async with client.get(
        f"/api/v2.0/projects/{project}/repositories",
        params={
            "page": page,
            "page_size": page_size,
        },
    ) as resp:
        repos = await resp.json()
        return [p["name"] for p in repos]


async def list_artifacts(
    client: aiohttp.ClientSession,
    project_name: str,
    repository_name: str,
    page: int,
    page_size: int,
) -> list[str]:
    async with client.get(
        f"/api/v2.0/projects/{project_name}/repositories/{repository_name}/artifacts",
        params={
            "page": page,
            "page_size": page_size,
        },
    ) as resp:
        repos = await resp.json()
        return [p["digest"] for p in repos]


async def resolve_artifact(
    client: aiohttp.ClientSession,
    project_name: str,
    repository_name: str,
    reference: str,
) -> Optional[str]:
    async with client.get(
        f"/api/v2.0/projects/{project_name}/repositories/{repository_name}/artifacts/{reference}",
        params={
            "page": 1,
            "page_size": 1,
        },
    ) as resp:
        if resp.status == 200:
            res = await resp.json()
            return res["digest"]
