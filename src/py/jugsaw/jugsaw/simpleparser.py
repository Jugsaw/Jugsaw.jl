import lark, json
from collections import OrderedDict
import numpy as np
import enum, pdb

####################### Object
# the JSON grammar in EBNF format
# dict is not allowed
class JugsawObject(object):
    def __init__(self, typename:str, fields:list):
        self.typename = typename
        self.fields = fields

    def __str__(self):
        fields = ", ".join([f"{repr(val)}" for val in self.fields])
        return f"{self.typename}({fields})"

    def __eq__(self, target):
        # NOTE: we do not need to check fields as long as their types are the same
        return isinstance(target, JugsawObject) and target.typename == self.typename and all([x==y for x, y in zip(target.fields, self.fields)])

    __repr__ = __str__


# Convert the grammar into a JugsawIR tree.
class JugsawTransformer(lark.Transformer):
    def object(self, items):
        return items[0]
    def genericobj1(self, items):
        return JugsawObject("", items[0])
    def genericobj2(self, items):
        return JugsawObject(items[0], items[1])
    def genericobj3(self, items):
        return JugsawObject(items[1], items[0])
    def var(self, items):
        return str(items[0])
    # primitive types
    def list(self, items):
        return [] if items[0] == None else list(items)
    def string(self, items):
        return json.loads(items[0])
    def number(self, items):
        return float(items[0])
    def true(self, items):
        return True
    def false(self, items):
        return False
    def null(self, items):
        return None

class JDataType(object):
    def __init__(self, name:str, fieldnames:list, fieldtypes:list):
        self.name = name
        self.fieldnames = fieldnames
        self.fieldtypes = fieldtypes

class TypeTable(object):
    def __init__(self, defs:OrderedDict={}):
        self.defs = defs

# constants
# parse an object
jp = lark.Lark.open("jugsawir.lark", rel_to=__file__, start='object', parser='lalr', transformer=JugsawTransformer())

def ir2adt(ir:str):
    return jp.parse(ir)

############################ adt to py
class Call(object):
    def __init__(self, fname, args, kwargs):
        self.fname = fname
        self.args = args
        self.kwargs = kwargs

    def __str__(self):
        args = ', '.join([repr(arg) for arg in self.args])
        kwargs = ', '.join([f'{k} = {repr(self.kwargs[k])}' for k in self.kwargs])
        return f"{self.fname}({args}, {kwargs})"

class Demo(object):
    def __init__(self, fcall, result, meta):
        self.fcall = fcall
        self.result = result
        self.meta = meta

    def __str__(self):
        return f"{self.fcall} = {repr(self.result)}"

def load_app(s:str):
    obj, typesadt = ir2adt(s)
    tt = load_typetable(typesadt)
    ############ load app
    name, method_names, _method_demos = obj.fields
    method_demos = makedict(_method_demos)
    demos = OrderedDict()
    for fname in aslist(method_names):
        demos[fname] = []
        for demo in aslist(method_demos[fname]):
            (_fcall, result, meta) = demo.fields
            _fname, args, kwargs = _fcall.fields
            jf = Call(fname, args.fields, OrderedDict(zip(aslist(tt.defs[kwargs.typename].fieldnames), kwargs.fields)))
            demo = Demo(jf, result, makedict(meta))
            demos[fname].append(demo)
    return (name, demos, tt)

# showing demo python inputs
def adt2py(adt):
    if isinstance(adt, JugsawObject):
        return tuple([adt2py(x) for x in adt.fields])
    elif isinstance(adt, list):
        return [adt2py(x) for x in adt]
    elif isdirectrepresentable(adt):
        return adt
    else:
        raise Exception(f"{type(adt)} can not be parsed to python object!")

def aslist(obj):
    return obj.fields[1]

def makedict(adt):
    pairs = aslist(adt.fields[0])
    return OrderedDict([(pair.fields[0], pair.fields[1]) for pair in pairs])

def load_typetable(ast:JugsawObject):
    #for obj in ast
    types, typedefs = ast.fields
    defs = makedict(typedefs)
    for type in defs:
        elem = defs[type]
        name, fieldnames, fieldtypes = elem.fields
        defs[type] = JDataType(name, fieldnames, fieldtypes)
    return TypeTable(defs)

# convert a Jugsaw tree to a dict
def isdirectrepresentable(obj):
    return (obj is None) or any([isinstance(obj, tp) for tp in (int, str, float, bool)])

def py2adt(obj):
    if isdirectrepresentable(obj):
        return obj
    elif isinstance(obj, np.integer):
        return int(obj)
    elif isinstance(obj, np.floating):
        return float(obj)
    elif isinstance(obj, dict) or isinstance(obj, OrderedDict):
        return JugsawObject("JugsawIR.JDict", [JugsawObject("JugsawIR.JArray", [[len(obj)], [py2adt(item) for item in obj.items()]])])
    elif isinstance(obj, list):
        return JugsawObject("JusawIR.JArray", [[len(obj)], [py2adt(x) for x in obj]])
    elif isinstance(obj, np.ndarray):
        vec = np.reshape(obj, -1, order="F")
        return JugsawObject("JugsawIR.JArray", [list(obj.shape), [py2adt(x) for x in vec]])
    elif isinstance(obj, tuple):
        return JugsawObject("Core.Tuple", [py2adt(x) for x in obj])
    elif isinstance(obj, enum.Enum):
        return JugsawObject("JugsawIR.JEnum", [type(obj).__name__, obj.name, [str(x.name) for x in type(obj)]])
    elif isinstance(obj, complex):
        return JugsawObject("Base.Complex", [obj.real, obj.imag])
    else:
        return JugsawObject(str(type(obj)), [getattr(obj, x) for x in obj.__dict__.keys()])

###################### ADT to IR
def adt2ir(x):
    return json.dumps(_adt2ir(x))

def _adt2ir(x):
    if isinstance(x, JugsawObject):
        return make_object_dict(x.typename, [_adt2ir(v) for v in x.fields])
    elif isinstance(x, list):
        return [_adt2ir(v) for v in x]
    elif isdirectrepresentable(x):
        return x
    else:
        raise Exception(f"type can not be casted to IR, got: {x} of type {type(x)}")

def py2ir(py):
    return adt2ir(py2adt(py))

def make_object_dict(T:str, fields:list):
    return {"type" : T, "fields" : fields}

if __name__ == "__main__":
    import pdb
    res = jp.parse("""
            {"type" : "Jugsaw.People{Core.Int}", "fields" : [32]}
            """)
    print(res)
    assert res == JugsawObject("Jugsaw.People{Core.Int}", [32])
    res = jp.parse("""
            {"type":"Jugsaw.TP", "fields":[]}
            """)
    print(res)
    assert res == JugsawObject("Jugsaw.TP", [])
    with open("../../../jl/Jugsaw/test/testapp/demos.json", "r") as f:
        s = f.read()
    print(load_app(s))

    assert py2dict(3.0) == 3.0
    assert py2dict("3.0") == "3.0"
    assert py2dict({"x":3}) == {"fields": [["x"], [3]]}
    assert py2dict(2+5j) == {"fields": [2, 5]}
    assert py2dict(np.array([[1, 2, 3], [4, 5, 6]])) == {"fields": [[2, 3], [1, 4, 2, 5, 3, 6]]}
    class Color(enum.Enum):
        RED = 1
        GREEN = 2
        BLUE = 3
    assert py2dict([1, Color.RED]) == [1, {"fields":["Color", "RED", ["RED", "GREEN", "BLUE"]]}]
    
    obj = JugsawObject("Jugsaw.TP", [])
    assert py2dict(obj) == {"fields" : ["Jugsaw.TP", []]}
