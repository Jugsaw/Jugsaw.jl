import lark
import numpy as np
import json
import pdb

####################### Type system
class FuncName(object):
    def __init__(self, module:str, name:str):
        self.module = module
        self.name = name
    def __str__(self):
        return f"{self.module}.{self.name}"

class TypeName(object):
    def __init__(self, module:str, name:str):
        self.module = module
        self.name = name
    def __str__(self):
        return f"{self.module}.{self.name}"

class JugsawType(object):
    def __init__(self, module:str, typename:str, typeparams):
        self.module = module
        self.typename = typename
        # typeparams can be list or None (absent)
        self.typeparams = typeparams

    def __str__(self):
        if isinstance(self.typeparams, list):
            typeparams = ", ".join([str(x) for x in self.typeparams])
            return f"{self.module}.{self.typename}" + "{" + typeparams + "}"
        else:
            return f"{self.module}.{self.typename}"

    def __eq__(self, target):
        return isinstance(target, JugsawType) and target.module == self.module and target.typename == self.typename and ((self.typeparams == None and target.typeparams == None) or all([x==y for x, y in zip(self.typeparams, target.typeparams)]))

    __repr__ = __str__

class Symbol(object):
    def __init__(self, s:str):
        self.string = s

    def __str__(self) -> str:
        return ":"+self.string

    def __eq__(self, target) -> bool:
        if not isinstance(target, Symbol):
            return False
        return self.string == target.string

    __repr__ = __str__

####################### Object
# the JSON grammar in EBNF format
# dict is not allowed
class JugsawObject(object):
    def __init__(self, type:JugsawType, values:list, fields:list):
        self.type = type
        self.values = values
        self.fields = fields
        #for field, value in zip(fields, values):
        #    if field not in self.__dict__:
        #        self.__dict__[field] = value

    def __str__(self):
        typeparams = ", ".join([f"{name} = {val}" for name, val in zip(self.fields, self.values)])
        return f"{self.type}(" + typeparams + ")"

    def __eq__(self, target):
        # NOTE: we do not need to check fields as long as their types are the same
        return isinstance(target, JugsawObject) and target.type == self.type and all([x==y for x, y in zip(target.values, self.values)])

    __repr__ = __str__

# Convert the grammar into a JugsawIR tree.
class JugsawTransformer(lark.Transformer):
    def object(self, items):
        return items[0]
    # parsing type
    def type(self, items):
        return items[0]
    def typewithparams(self, items):
        return JugsawType(*items[0], [] if items[1] == None else items[1:])
    def typewithoutparams(self, items):
        return JugsawType(*items[0], None)
    def typename(self, items):
        return (".".join(items[0]), items[1])
    def funcname(self, items):
        return (".".join(items[0]), "#"+items[1])
    def var(self, items):
        return str(items[0])
    def typeparam(self, items):
        return items[0]

    # primitive types
    def symbol(self, items):
        return Symbol(items[0])
    def tuple(self, items):
        if items[0] == None:
            return ()
        return tuple(items)
    def genericobj(self, items):
        d = dict(items)
        tp, values, fields = jtp.parse(d["type"]), d["values"], d["fields"]
        # fallback
        return JugsawObject(tp, values, fields)
    def pair(self, items):
        return tuple(items)
    def list(self, items):
        return [] if items[0] == None else list(items)
    def string(self, items):
        return items[0][1:-1]
    def float(self, items):
        return float(items[0])
    def integer(self, items):
        return int(items[0])
    def bool(self, items):
        return items[0]
    def true(self, items):
        return True
    def false(self, items):
        return False
    def null(self, items):
        return None
    def modname(self, items):
        return items

# convert a Jugsaw tree to a dict
def todict(obj):
    if isinstance(obj, JugsawObject):
        return {"type" : str(obj.type), "values" : todict(obj.values), "fields" : todict(obj.fields)}
    elif isinstance(obj, Symbol):  # within type
        return str(obj)
    elif isinstance(obj, tuple):    # within type
        return str(obj)
    elif isinstance(obj, list):
        return [todict(x) for x in obj]
    elif isinstance(obj, JugsawType):
        return str(obj)
    else:
        return obj

# constants
# parse an object
jp = lark.Lark.open("jugsawir.lark", rel_to=__file__, start='object', parser='lalr', transformer=JugsawTransformer())
# parse an type
jtp = lark.Lark.open("jugsawir.lark", rel_to=__file__, start='type', parser='lalr', transformer=JugsawTransformer())

if __name__ == "__main__":
    import pdb
    res = jtp.parse("""Base.Array{Core.Float64, 1}""")
    print(res)
    assert res == JugsawType("Base", "Array", [JugsawType("Core", "Float64", None), 1])

    res = jtp.parse("""Base.Array{true, 1}""")
    print(res)
    assert res == JugsawType("Base", "Array", [True, 1])

    res = jtp.parse("""Core.Tuple{}""")
    print(res)
    assert res == JugsawType("Core", "Tuple", [])

    res = jtp.parse("""Base.Array{Core.Float64, (:x, :y)}""")
    print(res)
    assert res == JugsawType("Base", "Array", [JugsawType("Core", "Float64", None), (Symbol("x"), Symbol("y"))])

    res = jp.parse("""
            {"type" : "Jugsaw.People{Core.Int}", "values" : [32], "fields" : ["age"]}
            """)
    print(res)
    assert res == JugsawObject(JugsawType("Jugsaw", "People", [JugsawType("Core", "Int", None)]), [32], ["age"])
    res = jp.parse("""
            {"type":"Jugsaw.TP", "values":[], "fields":[]}
            """)
    print(res)
    assert res == JugsawObject(JugsawType("Jugsaw", "TP", None), [], [])

    res = jtp.parse("Jugsaw.JugsawFunctionCall{Main.#solve, Core.Tuple{Main.IndependentSetConfig, GenericTensorNetworks.CountingMax{2}}, Core.NamedTuple{(:usecuda, :seed), Core.Tuple{Core.Bool, Core.Int64}}}")
    print(res)
