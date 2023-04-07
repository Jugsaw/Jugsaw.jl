import requests
from typing import Any

from .model import CallMsg, ArgsMsg


# Usage
# app = App("helloworld")
# res = app.greet("Jugsaw")
# print(res())
class App(object):
    def __init__(self, name: str, *, endpoint: str = "http://localhost:8081") -> None:
        self._name = name
        self._endpoint = endpoint

    def __getattribute__(self, __name: str):
        if __name.startswith("_"):
            return super(App, self).__getattribute__(__name)
        else:
            return Method(self, __name)


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
        return f"{self.app._endpoint}/actors/{self.app._name}.{self.method}"


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

    def __call__(self, *args: Any, sig:str="", fname:str="",  **kwds: Any) -> ObjectRef:
        payload = CallMsg(__type__=sig, fname=fname,args=ArgsMsg(data=args), kwargs=kwds).dict(by_alias=True)
        r = requests.post(self.url, json=payload)
        return ObjectRef(self, r.json()["object_id"])
