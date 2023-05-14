import os
import requests
from typing import Any, Optional
from simpleparser import load_app, Demo, todict, JugsawObject

class App(object):
    def __init__(self, name: str, demos, typetable, uri: Optional[str] = None) -> None:
        self._name = name
        self._uri = uri or os.getenv(
            "JUGSAW_ENDPOINT", "http://localhost:8081"
        )
        self._type_table = typetable
        self._method_demos = demos

    def __getattribute__(self, __name: str):
        if __name.startswith("_"):
            return super(App, self).__getattribute__(__name)
        else:
            return DemoRefs(f"{self._uri}/actors/{self.name}.{__name}", self._method_demos[__name])

    # this is for autocompletion!
    def __dir__(self):
        return self.demos.keys()

def request_app(uri:str, appname:str):
    if uri[:4] != "http":
        path = uri
        with open(os.path.join(path, "demos.json"), "r") as f:
            retstr = f.read()
    else:
        demo_url = os.path.join(uri, "apps", appname, "demos")
        r = requests.get(demo_url) # Deserialize
        retstr = r.body
    print(retstr)
    name, demos, tt = load_app(retstr, uri)
    return App(name, demos, tt, uri)

class DemoRefs(object):
    def __init__(self, name: str, demos:list, uri:str) -> None:
        self.name = name
        self.demos = demos
        self.uri = uri

    def __getitem__(self, i:int):
        return DemoRef(self.demos[i])

    def __call__(self, *args, **kwargs):
        if len(self.demos) == 1:
            return self[0].__call__(*args, **kwargs)
        else:
            raise ValueError("multiple demos found, please use choose a demo by indexing, e.g. `demos[0]`")

    def __doc__(self):
        return self.demos[0].meta["docstring"]

class DemoRef(object):
    def __init__(self, demo:Demo, uri:str) -> None:
        self.demo = demo
        self.uri = uri

    def __call__(self, *args, **kwargs):
        fcall = self.demo.fcall
        payload = {"type": "JugsawIR.Call", "values":[fcall.fname,
                                                      JugsawObject(fcall.args.typename, [py2adt(arg) for arg in args]),
                                                      JugsawObject(fcall.kwargs.typename, [py2adt(kw) for kw in kwargs])]}
        print(payload)
        r = requests.post(self.url, json=payload)
        return ObjectRef(self, r.json()["object_id"])

    def __doc__(self):
        return self.demo.meta["docstring"]

    @property
    def url(self) -> str:
        return f"{self.uri}/method"

class ObjectRef(object):
    def __init__(self, actor:DemoRefs, object_id: str):
        self.actor = actor
        self.object_id = object_id

    def __call__(self):
        url = f"{self.actor.url}/fetch"
        resp = requests.post(url, json={"object_id": self.object_id})
        return resp.text