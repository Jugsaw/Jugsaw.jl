import os
import requests
from typing import Any, Optional

from .model import CallMsg


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

    # this is for autocompletion!
    def __dir__(self):
        return self.demos.keys()

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
        return resp.text


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
        payload = {"type":str(sig), "values":[str(fname), args, kwds], "fields":["fname", "args", "kwargs"]}
        #).dict(by_alias=True)
        print(payload)
        r = requests.post(self.url, json=payload)
        return ObjectRef(self, r.json()["object_id"])
