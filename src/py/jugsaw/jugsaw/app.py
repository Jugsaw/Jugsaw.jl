import os
import copy, uuid
import requests
from typing import Any, Optional
from collections import OrderedDict
from .simpleparser import load_app, Demo, JugsawObject, adt2py
from .remotecall import request_app_data, ClientContext, call

class App(object):
    def __init__(self, name: str, method_demos:OrderedDict, type_table, context:ClientContext) -> None:
        # TODO: fix the following code
        self.name = name
        self.method_demos = method_demos
        self.type_table = type_table
        self.context = context

    def __getitem__(self, __name: str):
        return super(App, self).__getattribute__(__name)

    def __getattr__(self, fname: str):
        context = copy.deepcopy(self["context"])
        context.appname = self["name"]
        context.fname = fname
        return DemoRefs(fname, self["method_demos"][fname], context)

    # this is for autocompletion!
    def __dir__(self):
        return list(self["method_demos"].keys())

def request_app(context:ClientContext, appname:str):
    return App(*request_app_data(context, appname))

class DemoRefs(object):
    def __init__(self, name: str, demos:list, context:ClientContext) -> None:
        self.name = name
        self.demos = demos
        self.context = context
        self.__doc__ = self.demos[0].meta["docstring"]

    def __getitem__(self, i:int):
        return DemoRef(self.demos[i], self.context)

    def __call__(self, *args, **kwargs):
        if len(self.demos) == 1:
            return self[0].__call__(*args, **kwargs)
        else:
            raise ValueError("multiple demos found, please use choose a demo by indexing, e.g. `demos[0]`")

    def input(self):
        if len(self.demos) == 1:
            return self[0].input()
        else:
            raise ValueError("multiple demos found, please use choose a demo by indexing, e.g. `demos[0]`")

    def result(self):
        if len(self.demos) == 1:
            return self[0].result()
        else:
            raise ValueError("multiple demos found, please use choose a demo by indexing, e.g. `demos[0]`")


class DemoRef(object):
    def __init__(self, demo:Demo, context:ClientContext) -> None:
        self.demo = demo
        self.context = context
        self.__doc__ = self.demo.meta["docstring"]

    def __call__(self, *args, **kwargs):
        return call(self.context, self.demo, *args, **kwargs)

    def input(self):
        args = self.demo.fcall.args
        kwargs = self.demo.fcall.kwargs
        return tuple([adt2py(arg) for arg in args]), {k:adt2py(v) for k, v in kwargs.items()}

    def result(self):
        result = self.demo.result
        return adt2py(result)
