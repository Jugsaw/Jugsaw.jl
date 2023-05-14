import lark
from collections import OrderedDict
import numpy as np
import enum

####################### Object
# the JSON grammar in EBNF format
# dict is not allowed
class JugsawObject(object):
    def __init__(self, typename:str, fields:list):
        self.typename = typename
        self.fields = fields

    def __str__(self):
        fields = ", ".join([f"{val}" for val in self.fields])
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
        return items[0][1:-1]
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

class Demo(object):
    def __init__(self, fcall, result, meta):
        self.fcall = fcall
        self.result = result
        self.meta = meta

def load_app(s:str):
    obj, typesadt = ir2adt(s)
    tt = load_typetable(typesadt)
    ############ load app
    name, method_names, _method_demos = obj.fields
    ks, vs = _method_demos.fields
    method_demos = dict(zip(ks, vs))
    demos = OrderedDict()
    for fname in method_names:
        demos[fname] = []
        for demo in method_demos[fname]:
            (_fcall, result, meta) = demo.fields
            _fname, args, kwargs = _fcall.fields
            jf = Call(fname, args.fields, dict(zip(tt.defs[kwargs.typename].fieldnames, kwargs.fields)))
            demo = Demo(jf, result, dict(zip(meta.fields[0], meta.fields[1])))
            demos[fname].append(demo)
    return name, demos, tt

def load_typetable(ast:JugsawObject):
    #for obj in ast
    types, typedefs = ast.fields
    ks, vs = typedefs.fields
    defs = dict(zip(ks, vs))
    d = {}
    for type in types:
        elem = defs[type]
        name, fieldnames, fieldtypes = elem.fields
        d[type] = JDataType(name, fieldnames, fieldtypes)
    return TypeTable(d)

# convert a Jugsaw tree to a dict
def py2dict(obj):
    if (obj is None) or any([isinstance(obj, tp) for tp in (int, str, float, bool, np.number)]):
        return obj
    elif isinstance(obj, dict):
        return {"fields" : [py2dict([k for k in obj.keys()]), py2dict([v for v in obj.values()])]}
    elif isinstance(obj, list):
        return [py2dict(x) for x in obj]
    elif isinstance(obj, enum.Enum):
        return {"fields":[type(obj).__name__, obj.name, [str(x.name) for x in type(obj)]]}
    elif isinstance(obj, np.ndarray):
        if np.ndim(obj) == 1:
            return [py2dict(x) for x in obj]
        else:
            vec = np.reshape(obj, -1, order="F")
            return {"fields": [list(obj.shape), py2dict(vec)]}
    elif isinstance(obj, complex):
        return {"fields": [obj.real, obj.imag]}
    else:
        return {"fields": [getattr(obj, x) for x in obj.__dict__.keys()]}

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