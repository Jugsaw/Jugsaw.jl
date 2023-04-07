from jugsaw import App, Method
import gradio as gr
import json
import pdb
import copy

def load_methods(filename):
    with open(filename) as f:
        d = json.load(f)
    return d["data"]

def flatten(lst : list):
    lst = []
    for item in lst:
        if isinstance(item, list):
            for x in flatten(item):
                lst.append(x)
        else:
            lst.append(item)
    return lst

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
        res = Method(self.app, "greet")["0"](args, kwargs, sig=self.sig, fname=self.fname)
        result = res()
        flatten_result = {}
        extract_flatten(result, flatten_result, self.result_map)
        fl = [flatten_result[i] for i in range(len(flatten_result))]
        return fl

    def render_gr(self):
        # clear data
        inputs = []
        self.args_map = [render_arg(arg, f"Arg {i}", inputs) for (i, arg) in enumerate(self.args)]
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
        return newargs, newkwargs

def render_nested(args, inputs, smap):
    if isinstance(smap, list):
        for (i, arg) in enumerate(args):
            args[i] = render_nested(arg, inputs, smap[i])
        return args
    elif isinstance(smap, dict):
        for k in args:
            if k != "__type__":
                args[k] = render_nested(args[k], inputs, smap[k])
        return args
    else:
        return inputs[smap]


def extract_flatten(args, flat, smap):
    if isinstance(smap, list):
        for (i, arg) in enumerate(args):
            extract_flatten(arg, flat, smap[i])
    elif isinstance(smap, dict):
        for k in smap:
            extract_flatten(args[k], flat, smap[k])
    else:
        flat[smap] = [[x] for x in args] if isinstance(args, list) else args


# a function name is contained in the __type__ field
def polish_fname(name):
    if isinstance(name, dict):
        return name["__type__"]
    else:
        return name


def render_arg(arg, label, inputs):
    if isinstance(arg, float):
        inputs.append(gr.Number(label=label, value=arg))
        return len(inputs)-1
    elif isinstance(arg, int):
        inputs.append(gr.Number(label=label, value=arg))
        return len(inputs)-1
    elif isinstance(arg, str):
        inputs.append(gr.Textbox(label=label, value=arg))
        return len(inputs)-1
    elif isinstance(arg, list):
        df = gr.Dataframe(row_count = (len(arg), "dynamic"), col_count=(1,"fixed"), label=label, interactive=1, headers=[label], value=[[ai] for ai in arg])
        inputs.append(df)
        return len(inputs)-1
    elif isinstance(arg, dict):   # generic type
        smap = {}
        for k in arg:
            if k != "__type__":
                smap[k] = render_arg(arg[k], k, inputs)
        return smap
    else:
        raise Exception(f"input argument type not handled: {arg}")


filename = "../app/demo.json"
demos = load_methods(filename)
app = App("helloworld", demos)

with gr.Blocks() as jugs:
    for sig in demos:
        fdef = demos[sig]["first"]
        outdef = demos[sig]["second"]
        fname = polish_fname(fdef["fname"])
        with gr.Tab(fname):
            fargs = fdef["args"]
            rd = MethodRender(app, sig, fname, fdef["args"]["data"], fdef["kwargs"], outdef)
            inputs, outputs = rd.render_gr()
            launch = gr.Button("Go!")
            print(inputs)
            launch.click(
                    rd.flatten_call,
                    inputs = inputs,
                    outputs = outputs
                    )

if __name__ == "__main__":
    jugs.launch()   
