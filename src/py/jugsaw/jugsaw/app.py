import os
import requests
from typing import Any, Optional

from .model import CallMsg, ArgsMsg


# Usage
# app = App("helloworld")
# res = app.greet("Jugsaw")
# print(res())
class App(object):
    def __init__(self, name: str, demos, *, endpoint: Optional[str] = None) -> None:
        self.name = name
        self.endpoint = endpoint or os.getenv(
            "JUGSAW_ENDPOINT", "http://localhost:8081"
        )
        self.demos = demos


class Method(object):
    def __init__(self, app: App, method: str) -> None:
        self.app = app
        self.method = method

    def __getitem__(self, id: str):
        return Actor(self, id)

    def __call__(self, *args: Any, **kwds: Any) -> Any:
        return self.__getitem__("0")(*args, **kwds)

    @property
    def url(self) -> str:
        return f"{self.app.endpoint}/actors/{self.app.name}.{self.method}"


class ObjectRef(object):
    def __init__(self, actor: "Actor", object_id: str):
        self.actor = actor
        self.object_id = object_id

    def __call__(self):
        url = f"{self.actor.url}/fetch"
        resp = requests.post(url, json={"object_id": self.object_id})
        return resp.json()


class Actor(object):
    def __init__(self, method: Method, id: str):
        self.method = method
        self.id = id

    @property
    def url(self) -> str:
        return f"{self.method.url}/{self.id}/method"

    def __call__(
        self, args: Any, kwds: Any, sig: str = "", fname: str = ""
    ) -> ObjectRef:
        payload = CallMsg(
            type=sig, fields=["fname", "args", "kwargs"], values=[fname, args, kwds]
        ).dict(by_alias=True)
        r = requests.post(self.url, json=payload)
        return ObjectRef(self, r.json()["object_id"])
