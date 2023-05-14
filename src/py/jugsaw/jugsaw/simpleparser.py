import lark
from collections import OrderedDict

####################### Object
# the JSON grammar in EBNF format
# dict is not allowed
class JugsawVector(object):
    def __init__(self, storage:list):
        self.storage = storage

    def __str__(self):
        storage = ", ".join([f"{val}" for val in self.storage])
        return f"[{storage}]"

    def __eq__(self, target):
        # NOTE: we do not need to check fields as long as their types are the same
        return isinstance(target, JugsawVector) and all([x==y for x, y in zip(target.storage, self.storage)])

    __repr__ = __str__

class JugsawObject(object):
    def __init__(self, type:str, fields:JugsawVector):
        assert isinstance(fields, JugsawVector)
        self.type = type
        self.fields = fields

    def __str__(self):
        fields = ", ".join([f"{val}" for val in self.fields.storage])
        return f"{self.type}({fields})"

    def __eq__(self, target):
        # NOTE: we do not need to check fields as long as their types are the same
        return isinstance(target, JugsawObject) and target.type == self.type and all([x==y for x, y in zip(target.fields.storage, self.fields.storage)])

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
        return JugsawVector([] if items[0] == None else list(items))
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

# convert a Jugsaw tree to a dict
def todict(obj):
    if isinstance(obj, JugsawObject):
        return {"type" : str(obj.type), "values" : todict(obj.values), "fields" : todict(obj.fields)}
    elif isinstance(obj, JugsawVector):
        return [todict(x) for x in obj.storage]
    else:
        return obj

# constants
# parse an object
jp = lark.Lark.open("jugsawir.lark", rel_to=__file__, start='object', parser='lalr', transformer=JugsawTransformer())

def ir2adt(ir:str):
    return jp.parse(ir)

def request_app(s:str, uri):
    adt = ir2adt(s)
    appadt, typesadt = adt.storage
    tt = load_typetable(typesadt)
    return load_app(appadt, tt, uri)

def load_typetable(ast:JugsawObject):
    #for obj in ast
    types, typedefs = ast.fields.storage
    ks, vs = typedefs.fields.storage
    defs = dict(zip(ks.storage, vs.storage))
    d = {}
    for type in types.storage:
        elem = defs[type]
        name, fieldnames, fieldtypes = elem.fields.storage
        d[type] = JDataType(name, fieldnames.storage, fieldtypes.storage)
    return TypeTable(d)

def load_app(obj, tt:TypeTable, uri):
    name, method_names, _method_demos = obj.fields
    ks, vs = _method_demos.fields
    method_demos = dict(zip(ks.storage, vs.storage))
    demos = OrderedDict()
    for fname in method_names.storage:
        demos[fname] = []
        for demo in method_demos[_fname].storage:
            (_fcall, result, meta) = demo.fields
            _fname, args, kwargs = _fcall.fields
            jf = Call(fname, args.fields, dict(zip(get_fieldnames(kwargs, tt), kwargs.fields)))
            demo = Demo(jf, result, dict(zip(meta.fields[1].storage, meta.fields[2].storage)))
            demos[fname].append(demo)
    app = App(name, demos, tt, uri)
    return app

if __name__ == "__main__":
    import pdb
    res = jp.parse("""
            {"type" : "Jugsaw.People{Core.Int}", "fields" : [32]}
            """)
    print(res)
    assert res == JugsawObject("Jugsaw.People{Core.Int}", JugsawVector([32]))
    res = jp.parse("""
            {"type":"Jugsaw.TP", "fields":[]}
            """)
    print(res)
    assert res == JugsawObject("Jugsaw.TP", JugsawVector([]))
    with open("../../../jl/Jugsaw/test/testapp/demos.json", "r") as f:
        s = f.read()
    print(request_app(s, ""))