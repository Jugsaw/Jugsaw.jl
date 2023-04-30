import os
import requests
from typing import Any, Optional

from .model import CallMsg


# Usage
# app = App("helloworld")
# res = app.greet("Jugsaw")
# print(res())

def query_apps(endpoint:str):
    # return the list of apps
    pass

def query_methods(endpoint:str, app:str):
    # return the list of apps
    pass

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
            #return Method(self, __name)
            return Method(self, self._demos[__name])

    # this is for autocompletion!
    def __dir__(self):
        return self.demos.keys()

    def query_type(self, type:str):
        pass

    def query_function(self, method:str):
        pass

class Method(object):
    def __init__(self, app: App, name: str, instances:list) -> None:
        self.app = app
        self.name = name
        self.instances = instances

    def __getitem__(self, id: str):
        return Actor(self, id)

    def __call__(self, *args: Any, **kwds: Any) -> Any:
        return self.__getitem__("0")(*args, **kwds)

    def __doc__(self):
        self.name["docstring"]

    @property
    def url(self) -> str:
        return f"{self.app.endpoint}/actors/{self.app.name}.{self.name}"

class Type(object):
    def __init__(self, app: App, name: str) -> None:
        self.app = app
        self.name = name

    def __getitem__(self, id: str):
        return Actor(self, id)

    def __call__(self, *args: Any, **kwds: Any) -> Any:
        return self.__getitem__("0")(*args, **kwds)

    def __doc__(self):
        self.method["docstring"]

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
        print(payload)
        r = requests.post(self.url, json=payload)
        return ObjectRef(self, r.json()["object_id"])


# demo is a vector of function names + a dict from function name to function instances,
# a function instance is a triple of signature, args and kwargs,
# args is a tuple of objects,
# kwargs is a named-tuple.
# object is specified as [field1, field2, ...], in the future, we can omit the "fields", since they are in the type system.
# except primitive objects can be specified directly.

# query functions
# query data types