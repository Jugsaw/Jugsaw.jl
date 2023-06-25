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
    config = get_config()
    # 1. create project
    async with client.post(
        "/api/v2.0/projects",
        json={
            "project_name": name,
            "public": False,
            "storage_limit": -1,
        },
    ) as resp:
        assert resp.status == 201
    # 2. create webhook
    async with client.post(
        f"/api/v2.0/projects/{name}/webhook/policies",
        json={
            "enabled": True,
            "event_types": ["PUSH_ARTIFACT"],
            "targets": [
                {
                    "type": "http",
                    "address": "https://api.jugsaw.co/v1/hook/harbor",
                    "skip_cert_verify": False,
                    "payload_format": "CloudEvents",
                    "auth_header": f"Bearer {config.registry_webhook_token}",
                }
            ],
            "name": "jugsaw",
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


class AppExampleCode(BaseModel):
    julia: Optional[str] = None
    python: Optional[str] = None


class AppMeta(BaseModel):
    demos: Optional[str] = None
    types: Optional[str] = None
    code: AppExampleCode = AppExampleCode()


async def get_labels(
    client: aiohttp.ClientSession,
    project_name: str,
    repository_name: str,
    reference: str,
) -> dict[str, str]:
    async with client.get(
        f"/api/v2.0/projects/{project_name}/repositories/{repository_name}/artifacts",
        params={"q": f"digest={reference}"},
    ) as resp:
        if resp.status == 200:
            res = await resp.json()
            assert len(res) == 1
            return res[0]["extra_attrs"]["config"].get("Labels", {})
        else:
            raise Exception("Failed to retrieve labels due to network issue.")


async def get_app_meta(
    client: aiohttp.ClientSession,
    project_name: str,
    repository_name: str,
    reference: str,
) -> AppMeta:
    labels = await get_labels(client, project_name, repository_name, reference)

    meta = AppMeta(
        demos=labels.get("jugsaw.demos"),
        types=labels.get("jugsaw.types"),
        code=AppExampleCode(
            julia=labels.get("jugsaw.code.julia"),
            python=labels.get("jugsaw.code.python"),
        ),
    )

    return meta


#####


class ArtifactResource(BaseModel):
    digest: str
    tag: str
    resource_url: str


class Repository(BaseModel):
    date_created: int
    name: str
    namespace: str
    repo_full_name: str
    repo_type: str


class ArtifactPushedData(BaseModel):
    resources: list[ArtifactResource]
    repository: Repository


from kubernetes import client, config, utils


def on_artifact_push(a: ArtifactPushedData):
    config.load_incluster_config()
    k8s_client = client.ApiClient()
    # FIXME: examine repo_type
    for x in a.resources:
        assert x.digest.startswith("sha256:")
        digest = x.digest[7:]
        digest_short = digest[:8]  # TODO: label has a limit on length (<= 63)
        name = f"{a.repository.namespace}-{a.repository.name}-{digest_short}"
        image = (
            f"harbor.jugsaw.co/{a.repository.namespace}/{a.repository.name}@{x.digest}"
        )
        deployment = {
            "apiVersion": "apps/v1",
            "kind": "Deployment",
            "metadata": {"name": name},
            "spec": {
                "replicas": 1,
                "selector": {"matchLabels": {"app": name}},
                "template": {
                    "metadata": {
                        "labels": {"app": name},
                        "annotations": {
                            "dapr.io/enabled": "true",
                            "dapr.io/app-id": name,
                            "dapr.io/app-port": "8088",  # TODO: read from GLOBAL CONFIG
                            "dapr.io/log-level": "debug",  # TODO: read from GLOBAL CONFIG
                        },
                    },
                    "spec": {
                        "serviceAccountName": "dapr-service-account",  # TODO: read from GLOBAL CONFIG
                        "imagePullSecrets": [
                            {"name": "harbor-registry-jugsaw-deploy"}
                        ],  # TODO: read from GLOBAL CONFIG
                        "containers": [
                            {
                                "name": name,
                                "image": image,
                                "imagePullPolicy": "IfNotPresent",
                                "env": [
                                    {
                                        "name": "JUGSAW_USER_NAME",
                                        "value": a.repository.namespace,
                                    },
                                    {
                                        "name": "JUGSAW_APP_NAME",
                                        "value": a.repository.name,
                                    },
                                    {
                                        "name": "JUGSAW_APP_VERSION",
                                        "value": digest,
                                    },
                                ],
                                "ports": [
                                    {
                                        "name": "http",
                                        "containerPort": 8088,
                                        "protocol": "TCP",
                                    }
                                ],
                            }
                        ],
                    },
                },
            },
        }

        utils.create_from_dict(k8s_client, deployment)
        # TODO: https://github.com/kubernetes-client/python/issues/571#issuecomment-908209994
        # wait until it become ready first
        # then we apply the keda scalar
        # because the SQS subscriber is only created on startup
        # or maybe we can create eh subscriber through dapr component explicitly?
        # In this case, the scalar metrics is not ready, it will turn into error mode.
        # By default it will scale to 0 immediately. We'd like to delay this process here.

        scalar = {
            "apiVersion": "keda.sh/v1alpha1",
            "kind": "ScaledObject",
            "metadata": {"name": name, "namespace": "jugsaw"},  # FIXME: GLOBAL CONFIG
            "spec": {
                "scaleTargetRef": {"name": name},
                "pollingInterval": 15,
                "cooldownPeriod": 300,
                "maxReplicaCount": 1,
                "minReplicaCount": 1,
                "idleReplicaCount": 0,
                "triggers": [
                    {
                        "type": "aws-sqs-queue",
                        "authenticationRef": {
                            "name": "keda-trigger-auth-aws-credentials"
                        },
                        "metadata": {
                            "queueURL": f"https://sqs.us-west-1.amazonaws.com/701218724223/{name}",
                            "queueLength": "5",
                            "awsRegion": "us-west-1",
                            "identityOwner": "operator",
                        },
                    }
                ],
            },
        }

        utils.create_from_dict(k8s_client, scalar)
