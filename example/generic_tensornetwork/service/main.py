from fastapi import FastAPI
from jugsaw import App, Method
import gradio as gr
import numpy as np
import json
import pdb
import copy
import logging
import re
from simpleparser import jp, JugsawObject

class MethodRender(object):
    def __init__(self, app, sig, fname, args, kwargs, results):
        self.app = app
        self.sig = sig
        self.fname = fname
        self.args = args
        self.kwargs = kwargs
        self.results = results
        # a map from structured inputs to the flatten inputs
        self.sig_map = None
        self.args_map = None
        self.kwargs_map = None
        self.result_map = None

    def flatten_call(self, *args):
        args, kwargs = self.render_input(args)
        res = Method(self.app, "greet")["0"](
            args, kwargs, sig=self.sig, fname=self.fname
        )
        result = res()
        flatten_result = {}
        extract_flatten(result, flatten_result, self.result_map)
        fl = [flatten_result[i] for i in range(len(flatten_result))]
        return fl

    def render_gr(self):
        # clear data
        inputs = []
        #self.args_map = [
            #render_arg(arg, f"#{i+1}", inputs) for (i, arg) in enumerate(self.args)
        #]
        self.args_map = render_arg(self.args, "Positional arguments", inputs)
        self.kwargs_map = render_arg(self.kwargs, "Keyword arguments", inputs)
        outputs = []
        self.result_map = render_arg(self.results, "Output", outputs)
        return inputs, outputs

    # convert flat inputs to structured inputs
    def render_input(self, inputs):
        newargs = copy.deepcopy(self.args)
        render_nested(newargs, inputs, self.args_map)
        newkwargs = copy.deepcopy(self.kwargs)
        render_nested(newkwargs, inputs, self.kwargs_map)
        logging.info(newargs)
        logging.info(newkwargs)
        return newargs, newkwargs


# args is the demo inputs
# inputs is the user inputs
# smap is a map from the argument index/name to the gradio input id
def render_nested(args, inputs, smap):
    if isinstance(args, list):
        for arg in args:
            render_nested(arg, inputs, smap)
    elif isinstance(args, JugsawObject):  # an object
        tp, values, fields = args.type, args.values, args.fieldnames
        # parsing arrays
        if tp.module == "Core" and tp.typename == "Array":
            if len(args.values) == 1:
                data_input = inputs[smap]
                rawdata = data_input.values[:,0].tolist()
                if len(rawdata) == 1 and rawdata[0] == '':
                    rawdata = []
                T = map_eltype_py(matched.group(1))
                values[1] = [T(i) for i in rawdata]
                values[0] = [len(values[1])]
                return args
            elif len(args.values) == 2:
                data_input = inputs[smap]
                rawdata = data_input.values
                T = map_eltype_py(matched.group(1))
                values[1] = [T(i) for i in np.reshape(rawdata.T, -1)]
                values[0] = [rawdata.shape[0], rawdata.shape[1]]
                return args
        elif tp.module == "Base" and tp.typename == "Dict":
            keys, vals = inputs[smap]
            Tk = map_eltype_py(tp.typeparams[0])
            Tv = map_eltype_py(tp.typeparams[1])
            values[0] = [Tk(k) for k in keys]
            values[1] = [Tv(v) for v in vals]
            return args
        # TODO: handle enum

        # fallback
        for k in range(len(values)):
            values[k] = render_nested(values[k], inputs, smap[k])
        return args
    else:
        return inputs[smap]


def extract_flatten(args, flat, smap):
    if isinstance(args, JugsawObject):
        tp, values, fields = args.type, args.values, args.fieldnames
        #for (i, arg) in enumerate(args):
            #extract_flatten(arg, flat, smap[i])
    #elif isinstance(args, dict):
        if tp.module == "Core" and tp.typename == "Array":
            size, storage = values
            ndims = len(size)
            if ndims == 1:
                flat[smap] = [[x] for x in values[1]]
            elif ndims == 2:
                flat[smap] = np.reshape(values[1], values[0])
        elif tp.module == "Base" and tp.typename == "Dict":
            flat[smap] = dict(zip(*values))
        raise NotImplementedError("array")
    elif isinstance(args, list):
        for k in range(len(values)):
            extract_flatten(values[k], flat, smap[k])
    else:
        flat[smap] = args


# a function name is contained in the type field
def polish_fname(name):
    if isinstance(name, list):
        return name[0]
    else:
        return name

# render arguments to gradio gadgets
def render_arg(arg, label, inputs, level=0):
    # the elementary input type
    if isinstance(arg, float):
        return push(inputs, gr.Number(label=label, value=arg))
    elif isinstance(arg, bool):
        return push(inputs, gr.Checkbox(label=label))
    elif isinstance(arg, int):
        return push(inputs, gr.Number(label=label, value=arg, precision=0))
    elif isinstance(arg, str):
        return push(inputs, gr.Textbox(label=label, value=arg))
    elif isinstance(arg, list):
        res = [render_arg(x, label + "[%d]"%i, inputs, level=0) for (i, x) in enumerate(arg)]
        return res
    elif isinstance(arg, JugsawObject):  # generic type
        tp, values, fields = arg.type, arg.values, arg.fieldnames
        _label = "␣"*(level) + " " + label #◼⋄
        gr.Markdown(f"{_label} = **{tp}**")
        if tp.module == "Core" and tp.typename == "Array":
            size, storage = values
            ndims = len(size)
            if ndims == 1:  # vector
                size, storage = values
                df = gr.Dataframe(
                    row_count=(int(size[0]), "dynamic"),
                    col_count=(1, "fixed"),
                    datatype=map_eltype(tp.typeparams[0]),
                    label=label, 
                    interactive=1,
                    headers=[label],
                    value=[[ai] for ai in storage],
                )
                return push(inputs, df)
            elif ndims==2:
                size, storage = values
                df = gr.Dataframe(
                    row_count=(int(size[0]), "dynamic"),
                    col_count=(int(size[1]), "dynamic"),
                    datatype=map_eltype(tp.typeparams[0]),
                    label=label, 
                    interactive=1,
                    headers=[f"C{i+1}" for i in range(size[1])],
                    value=np.reshape(storage, size),
                )
                return push(inputs, df)
            else:
                raise NotImplementedError("")
        elif tp.module == "Base" and tp.typename == "Dict":
            keys, vals = arg.values
            kt, vt = arg.type.typeparams
            df = gr.Dataframe(
                row_count=(len(keys), "dynamic"),
                col_count=(2, "fixed"),
                datatype=[map_eltype(kt), map_eltype(vt)],
                label=label, 
                interactive=1,
                headers=["keys", "values"],
                value=[[k, v] for k, v in zip(*values)],
            )
            return push(inputs, df)
        ###### Jugsaw.Universe ######
        elif tp.module == "Jugsaw.Universe":
            if tp.typename == "Enum":
                kind, value, options = values
                return push(inputs, gr.Choice(options, default=value))
            elif tp.typename == "MultiChoice":
                raise NotImplementedError(f"{tp.type}")  # TODO: fix the empty list issue.
            elif tp.typename == "Color":
                c = ColorPicker(label=label)
                return push(inputs, c)
            # TODO: MultiChoice, Code, Dataframe, File, RGBImage
        # no need to specialize tuple
        smap = []
        for (k, v) in zip(fields, values):
            smap.append(render_arg(v, "#"+k, inputs, level+1))
        return smap
    else:
        raise Exception(f"input argument type not handled: {arg}")

def push(stack, elem):
    stack.append(elem)
    return len(stack) - 1

# map Julia element type to Dataframes element type
def map_eltype(tp):
    if tp.module == "Core":
        if tp.typename == "String":
            return "str"
        elif tp.typename == "Float64":
            return "number"
        elif tp.typename == "Int64":
            return "number"
        elif tp.typename == "Bool":
            return "bool"
        #return "date"
        #return "markdown"
    raise NotImplementedError(f"{tp}")

def map_eltype_py(tp):
    if tp.module == "Core":
        if tp.typename == "String":
            return str
        elif tp.typename == "Float64":
            return float
        elif tp.typename == "Int64":
            return int
        elif tp.typename == "Bool":
            return bool
    raise NotImplementedError(f"{tp}")

#################### Main Program ###############
def load_methods(filename):
    with open(filename) as f:
        s = f.read()
        dd = jp.parse(s)
    return dd

def launch_jugsaw(demofile, appname, logging_level=logging.INFO):
    demos = load_methods(demofile)
    app = App(appname, demos)

    with gr.Blocks() as jugs:
        for k, demo in zip(*demos.values):
            fdef, outdef = demo.values
            fname, fargs, fkwargs = fdef.values
            fname = polish_fname(fname)
            with gr.Tab(fname):
                rd = MethodRender(
                    app, fdef.type, fname, fargs, fkwargs, outdef
                )
                inputs, outputs = rd.render_gr()
                launch = gr.Button("Go!")
                launch.click(rd.flatten_call, inputs=inputs, outputs=outputs)

    #server = FastAPI()
    #server = gr.mount_gradio_app(server, jugs, path="/jugsaw/example")
    logging.basicConfig(level=logging_level)
    jugs.launch()

launch_jugsaw("../app/demo.json", "helloworld", logging.INFO)
