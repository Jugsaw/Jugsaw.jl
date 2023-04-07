from jugsaw import App
import gradio as gr
import json
import pdb
import copy

def load_methods(filename):
    with open(filename) as f:
        d = json.load(f)
    return d["data"]

def func(*args):
    pdb.set_trace()
    fname = demos[inputs]["name"]
    res = getattr(app, sig)["0"](name, sig=sig, fname=fname)
    return res()

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
    def __init__(self, args, kwargs):
        self.args = args
        self.kwargs = kwargs
        # a map from structured inputs to the flatten inputs
        self.args_map = []
        self.kwargs_map = {}

    def render_gr(self):
        # clear data
        self.args_map = []
        self.kwargs_map = {}
        for (i, arg) in self.args:
            render_arg(arg, f"Arg {i}", self.args_map)
        for k in self.kwargs:
            render_arg(arg, k, self.kwargs_map)

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

# a function is rendered by the __type__
def polish_fname(name):
    if isinstance(name, dict):
        return name["__type__"]
    else:
        return name

def render_arg(arg, label, smap):
    if isinstance(arg, int):
        return gr.Number(label=label)
    elif isinstance(arg, str):
        return gr.Textbox(label=label)
    elif isinstance(arg, list):
        return gr.Dataframe(row_count = (3, "dynamic"), col_count=(1,"fixed"), label=label, interactive=1)
    elif isinstance(arg, dict):   # generic type
        inputs = []
        for k in arg:
            if k != "__type__":
                inputs.append(render_arg(arg[k], k))
        return inputs
    else:
        raise Exception(f"input argument type not handled: {arg}")


filename = "demo.json"
demos = load_methods(filename)
app = App("helloworld", demos)

with gr.Blocks() as jugs:
    for sig in demos:
        fdef = demos[sig]["first"]
        outdef = demos[sig]["second"]
        fname = polish_fname(fdef["fname"])
        with gr.Tab(fname):
            fargs = fdef["args"]
            fargs_dict = {f"Arg {i+1}":v for i, v in enumerate(fargs["data"])}
            input_args = render_arg(fargs_dict, "Positional arguments")
            input_kwargs = render_arg(fdef["kwargs"], "Keyword argument")
            output = render_arg(outdef, "Output")
            launch = gr.Button("Go!")
            print(flatten([input_args, input_kwargs]))
            pdb.set_trace()
            launch.click(
                    func,
                    inputs = flatten([input_args, input_kwargs]),
                    outputs = output
                    )

if __name__ == "__main__":
    jugs.launch()   
