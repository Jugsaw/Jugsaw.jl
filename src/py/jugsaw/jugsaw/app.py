import os
import copy, uuid
import requests
from typing import Any, Optional
from .simpleparser import load_app, Demo, JugsawObject

class ClientContext(object):
    def __init__(self,
            endpoint:str = "http://localhost:8088/",
            localurl:bool = False,
            project:str = "unspecified",
            appname:str = "unspecified",
            version:str = "1.0",
            fname:str = "unspecified"):
        self.endpoint = endpoint
        self.localurl = localurl
        self.project = project
        self.appname = appname
        self.version = version
        self.fname = fname

class App(object):
    def __init__(self, name: str, method_demos:dict, type_table, context:ClientContext) -> None:
        # TODO: fix the following code
        self._name = name
        self._method_demos = method_demos
        self._type_table = type_table
        self._context = context

    def __getattribute__(self, __name: str):
        if __name.startswith("_"):
            return super(App, self).__getattribute__(__name)
        else:
            context = copy.deepcopy(self.context)
            context.appname = self._name
            context.fname = __name
            return DemoRefs(__name, self._method_demos[__name], context)

    # this is for autocompletion!
    def __dir__(self):
        return self.demos.keys()

class DemoRefs(object):
    def __init__(self, name: str, demos:list, context:ClientContext) -> None:
        self.name = name
        self.demos = demos
        self.context = context

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
