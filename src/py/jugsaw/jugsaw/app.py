import os
import requests
from typing import Any, Optional

class App(object):
    def __init__(self, name: str, demos, *, endpoint: Optional[str] = None) -> None:
        self._name = name
        self._endpoint = endpoint or os.getenv(
            "JUGSAW_ENDPOINT", "http://localhost:8081"
        )
        self._demos = demos

    def __getattribute__(self, __name: str):
        if __name.startswith("_"):
            return super(App, self).__getattribute__(__name)
        else:
            return Method(f"{self._endpoint}/actors/{self.name}.{__name}", self._demos[__name])

    # this is for autocompletion!
    def __dir__(self):
        return self.demos.keys()

class Method(object):
    def __init__(self, uri:str, name: str, instances:list, meta:dict) -> None:
        self.uri = uri
        self.name = name
        self.instances = instances
        self.meta = meta

    def __call__(self, args: Any, kwds: Any, fname: str = ""):
        payload = {"type": "JugsawIR.Call", "values":[str(fname), args, kwds]}
        print(payload)
        r = requests.post(self.url, json=payload)
        return ObjectRef(self, r.json()["object_id"])

    def __doc__(self):
        self.meta["docstring"]

    @property
    def url(self) -> str:
        return f"{self.uri}/method"

class ObjectRef(object):
    def __init__(self, actor:Method, object_id: str):
        self.actor = actor
        self.object_id = object_id

    def __call__(self):
        url = f"{self.actor.url}/fetch"
        resp = requests.post(url, json={"object_id": self.object_id})
        return resp.text