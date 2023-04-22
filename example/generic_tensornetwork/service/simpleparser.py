import lark
import numpy as np

##################### Grammar
jugsaw_grammar = r"""
    object: genericobj
         | type
         | list
         | string
         | float
         | integer
         | bool
         | null

    type : (typename | funcname) ["{" [typeparam ("," typeparam)*] "}"]
    typename : var ("." var)+
    funcname : var ("." var)* "." "#" var 
    var : /[^\W0-9]\w*/
    typeparam: type
         | integer
         | float
         | tuple
         | symbol
         | bool
         | null
    symbol : ":" var
    tuple : "(" [typeparam ","] ")"
         | "(" typeparam ("," typeparam)+ ")"

    genericobj : "{" [pair ("," pair)*] "}"
    pair : string ":" object

    list : "[" [object ("," object)*] "]"
    string : ESCAPED_STRING
    float : SIGNED_FLOAT
    integer : INT
    bool : true | false
    true : "true"
    false : "false"
    null : "null"

    %import common.ESCAPED_STRING
    %import common.INT
    %import common.SIGNED_FLOAT
    %import common.WS
    %ignore WS
"""

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

# class JugsawTypeTransformer(lark.Transformer):
#     def type(self, items):
#         return JugsawType(items[0], items[1], None if items[2] == None else items[2:])
#     def var(self, items):
#         return str(items[0])
#     def typeparam(self, items):
#         return items[0]

#     def integer(self, items):
#         return int(items[0])
#     def bool(self, items):
#         return bool(items[0])
#     def null(self, items):
#         return None
#     def float(self, items):
#         return float(items)


# jtp = lark.Lark(r"""
#     type : var "." var ["{" [typeparam ("," typeparam)*] "}"]
#     var : /[^\W0-9]\w*/
#     typeparam: type
#          | integer
#          | float
#          | bool
#          | null

#     integer : INT
#     bool : "true" | "false"
#     null : "null"
#     float : SIGNED_FLOAT
#     %import common.INT
#     %import common.SIGNED_FLOAT
#     %import common.WS
#     %ignore WS
# """, start='type', parser='lalr', transformer=JugsawTypeTransformer())


####################### Object
# the JSON grammar in EBNF format
# dict is not allowed
class JugsawObject(object):
    def __init__(self, type:JugsawType, values:list, fieldnames:list):
        self.type = type
        self.values = values
        self.fieldnames = fieldnames
        #for field, value in zip(fieldnames, values):
        #    if field not in self.__dict__:
        #        self.__dict__[field] = value

    def __str__(self):
        typeparams = ", ".join([f"{name} = {val}" for name, val in zip(self.fieldnames, self.values)])
        return f"{self.type}(" + typeparams + ")"

    def __eq__(self, target):
        # NOTE: we do not need to check fieldnames as long as their types are the same
        return isinstance(target, JugsawObject) and target.type == self.type and all([x==y for x, y in zip(target.values, self.values)])

    __repr__ = __str__

class JugsawTransformer(lark.Transformer):
    def object(self, items):
        return items[0]
    # parsing type
    def type(self, items):
        return JugsawType(*items[0], None if items[1] == None else items[1:])
    def typename(self, items):
        return (".".join(items[:-1]), items[-1])
    def funcname(self, items):
        return (".".join(items[:-1]), "#"+items[-1])
    def var(self, items):
        return str(items[0])
    def typeparam(self, items):
        return items[0]

    def arraytype(self, items):
        return JugsawType("Core", "Array", items)
    def dicttype(self, items):
        return JugsawType("Base", "Dict", items)

    # primitive types
    def symbol(self, items):
        return items[0]
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
    def nestedlist(self, items):
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

jp = lark.Lark(jugsaw_grammar, start='object', parser='lalr', transformer=JugsawTransformer())
jtp = lark.Lark(jugsaw_grammar, start='type', parser='lalr', transformer=JugsawTransformer())

if __name__ == "__main__":
    import pdb
    res = jtp.parse("""Base.Array{Core.Float64, 1}""")
    print(res)
    assert res == JugsawType("Base", "Array", [JugsawType("Core", "Float64", None), 1])

    res = jtp.parse("""Base.Array{true, 1}""")
    print(res)
    assert res == JugsawType("Base", "Array", [True, 1])

    res = jtp.parse("""Base.Array{Core.Float64, (:x, :y)}""")
    print(res)
    assert res == JugsawType("Base", "Array", [JugsawType("Core", "Float64", None), ("x", "y")])

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
