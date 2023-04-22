from fastapi import FastAPI
from jugsaw import App, Method
import gradio as gr
import numpy as np
import json
import pdb
import copy
import logging
import re
from simpleparser import jp, jlp

# typename: ([^\W0-9]\w*\.[^\W0-9]\w*)
re_array = re.compile(r"^Core\.Array\{(.*), (\d+)\}")
re_vector = re.compile(r"^Core\.Array\{(.*), 1\}")
re_matrix = re.compile(r"^Core\.Array\{(.*), 2\}")
re_dict = re.compile(r"^Base\.Dict\{(.*), (.*)\}")
re_vector_of_tuple = re.compile(r"^Base\.Array\{Core\.Tuple\{(.*)\}, 1\}")
re_tuple_of_vector = re.compile(r"^Core\.Tuple\{(Base\.Array\{(.*), 1\})(, Base\.Array\{(.*), 1\})*\}")
re_multichoice = re.compile(r"^Jugsaw\.Universe\.MultiChoice\{(.*)\}")

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
    if isinstance(args, list):  # an object
        typeinfo, values, fields = args
        # parsing arrays
        if matched := re_vector.match(typeinfo):
            data_input = inputs[smap]
            rawdata = data_input.values[:,0].tolist()
            if len(rawdata) == 1 and rawdata[0] == '':
                rawdata = []
            T = map_eltype_py(matched.group(1))
            values[1] = [T(i) for i in rawdata]
            values[0] = [len(values[1])]
            return args
        elif matched := re_matrix.match(typeinfo):
            data_input = inputs[smap]
            rawdata = data_input.values
            T = map_eltype_py(matched.group(1))
            values[1] = [T(i) for i in np.reshape(rawdata.T, -1)]
            values[0] = [rawdata.shape[0], rawdata.shape[1]]
            return args
        elif matched := re_array.match(typeinfo):
            raise NotImplementedError("array")
        elif matched := re_dict.match(typeinfo):
            keys, vals = inputs[smap]
            Tk = map_eltype_py(matched.group(1))
            Tv = map_eltype_py(matched.group(2))
            values[0] = [Tk(k) for k in keys]
            values[1] = [Tv(v) for v in vals]
            return args
        # TODO: handle enum
        else:
            for k in range(len(args[1])):
                args[1][k] = render_nested(args[1][k], inputs, smap[k])
            return args
    else:
        #for i in range(len(args)):
        #    args[i] = render_nested(args[i], inputs, smap[i])
        #return args
        #if isinstance(args, list):
        #    # TODO: fix!!!!
        #    res = inputs[smap].values[:,0].tolist()
        #    if len(res) == 1 and res[0] == '':
        #        return []
        #    else:
        #        return res
        #else:
        return inputs[smap]


def extract_flatten(args, flat, smap):
    if isinstance(args, list):
        typeinfo, values, fields = args
        #for (i, arg) in enumerate(args):
            #extract_flatten(arg, flat, smap[i])
    #elif isinstance(args, dict):
        if re_vector.match(typeinfo):
            flat[smap] = [[x] for x in values[1]]
        elif re_matrix.match(typeinfo):
            flat[smap] = np.reshape(values[1], values[0])
        elif re_array.match(typeinfo):
            raise NotImplementedError("array")
        elif re_dict.match(typeinfo):
            flat[smap] = dict(zip(values[0], values[1]))
        else:
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
def render_arg(arg, label, inputs, level=0, typeinfo=None):
    # the elementary input type
    if isinstance(arg, float):
        return push(inputs, gr.Number(label=label, value=arg))
    elif isinstance(arg, bool):
        return push(inputs, gr.Checkbox(label=label))
    elif isinstance(arg, int):
        return push(inputs, gr.Number(label=label, value=arg, precision=0))
    elif isinstance(arg, str):
        return push(inputs, gr.Textbox(label=label, value=arg))
    elif isinstance(arg, list):  # generic type
        tp, values, fields = arg
        _label = "␣"*(level) + " " + label #◼⋄
        gr.Markdown(f"{_label} = **{tp}**")
        if tp == "Jugsaw.Universe.Enum":
            kind, value, options = values
            return push(inputs, gr.Choice(options, default=value))
        elif matched := re_vector.match(tp):
            size, storage = values
            df = gr.Dataframe(
                row_count=(int(size[0]), "dynamic"),
                col_count=(1, "fixed"),
                datatype=map_eltype(matched.group(1)),
                label=label, 
                interactive=1,
                headers=[label],
                value=[[ai] for ai in storage],
            )
            return push(inputs, df)
        elif matched := re_matrix.match(tp):
            size, storage = values
            df = gr.Dataframe(
                row_count=(int(size[0]), "dynamic"),
                col_count=(int(size[1]), "dynamic"),
                datatype=map_eltype(matched.group(1)),
                label=label, 
                interactive=1,
                headers=[f"C{i+1}" for i in range(size[1])],
                value=np.reshape(storage, size),
            )
            return push(inputs, df)
        elif matched := re_array.match(tp):
            raise NotImplementedError("")
        elif matched := re_dict.match(tp):
            keys, vals = values
            df = gr.Dataframe(
                row_count=(len(keys), "dynamic"),
                col_count=(2, "fixed"),
                datatype=[map_eltype(matched.group(1)), map_eltype(matched.group(2))],
                label=label, 
                interactive=1,
                headers=["keys", "values"],
                value=[[k, v] for k, v in zip(*values)],
            )
            return push(inputs, df)
        ###### Jugsaw.Universe ######
        elif matched := re_multichoice.match(tp):
            raise NotImplementedError("")  # TODO: fix the empty list issue.
        elif tp == "Jugsaw.Universe.Color":
            c = ColorPicker(label=label)
            return push(inputs, c)
        # TODO: MultiChoice, Code, Dataframe, File, RGBImage
        else:
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
    if tp == "Core.String":
        return "str"
    elif tp == "Core.Float64":
        return "number"
    elif tp == "Core.Int64":
        return "number"
    elif tp == "Core.Bool":
        return "bool"
        #return "date"
        #return "markdown"
    else:
        raise NotImplementedError(f"{tp}")

def map_eltype_py(tp):
    if tp == "Core.Int64":
        return int
    elif tp == "Core.Float64":
        return float
    elif tp == "Core.String":
        return str
    elif tp == "Core.Bool":
        return bool
    else:
        raise NotImplementedError(f"{tp}")

#################### Main Program ###############
def load_methods(filename):
    with open(filename) as f:
        s = f.read()
        d = json.loads(s)

        st = json.dumps(d[1][1][0][1][0][1][1][1][0][1][0])
        pdb.set_trace()
        d = jp.parse(s)
    pdb.set_trace()
    #return d[1][1]

def launch_jugsaw(demofile, appname, logging_level=logging.INFO):
    demos = load_methods(demofile)
    app = App(appname, demos)

    with gr.Blocks() as jugs:
        for k in range(len(demos)):
            demo = demos[k]
            fdef = demo[1][0]
            outdef = demo[1][1]
            fname, fargs, fkwargs = fdef[1]
            fname = polish_fname(fname)
            with gr.Tab(fname):
                rd = MethodRender(
                    app, fdef[0], fname, fargs, fkwargs, outdef
                )
                inputs, outputs = rd.render_gr()
                launch = gr.Button("Go!")
                launch.click(rd.flatten_call, inputs=inputs, outputs=outputs)

    #server = FastAPI()
    #server = gr.mount_gradio_app(server, jugs, path="/jugsaw/example")
    logging.basicConfig(level=logging_level)
    jugs.launch()

launch_jugsaw("../app/demo.json", "helloworld", logging.INFO)
