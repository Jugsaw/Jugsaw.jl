import lark
import pdb
####################### Type system
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
        print(target.typeparams), print(self.typeparams)
        return isinstance(target, JugsawType) and target.module == self.module and target.typename == self.typename and ((self.typeparams == None and target.typeparams == None) or all([x==y for x, y in zip(self.typeparams, target.typeparams)]))

    __repr__ = __str__

class JugsawTypeTransformer(lark.Transformer):
    def type(self, items):
        return JugsawType(items[0], items[1], None if items[2] == None else items[2:])
    def symbol(self, items):
        return str(items[0])
    def typeparam(self, items):
        return items[0]

    def integer(self, items):
        return int(items[0])
    def bool(self, items):
        return bool(items[0])
    def null(self, items):
        return None
    def float(self, items):
        return float(items)


jtp = lark.Lark(r"""
    type : symbol "." symbol ["{" [typeparam ("," typeparam)*] "}"]
    symbol : /[^\W0-9]\w*/
    typeparam: type
         | integer
         | float
         | bool
         | null

    integer : INT
    bool : "true" | "false"
    null : "null"
    float : SIGNED_FLOAT
    %import common.INT
    %import common.SIGNED_FLOAT
    %import common.WS
    %ignore WS
""", start='type', parser='lalr', transformer=JugsawTypeTransformer())


####################### Object
# the JSON grammar in EBNF format
# dict is not allowed
class JugsawObject(object):
    def __init__(self, type:JugsawType, values:list, fieldnames:list):
        self.type = type
        self.values = values
        self.fieldnames = fieldnames

    def __str__(self):
        typeparams = ", ".join([f"{name} = {val}" for name, val in zip(self.fieldnames, self.values)])
        return f"{self.type}(" + typeparams + ")"

    def __eq__(self, target):
        # NOTE: we do not need to check fieldnames as long as their types are the same
        return isinstance(target, JugsawObject) and target.type == self.type and all([x==y for x, y in zip(target.values, self.values)])

    __repr__ = __str__

class JugsawTransformer(lark.Transformer):
    def obj(self, items):
        return JugsawObject(
                #jtt.transform(jtp.parse(items[0])),
                items[0],
                items[1],
                items[2]
                )

    # parsing type
    def type(self, items):
        return JugsawType(items[0], items[1], None if items[2] == None else items[2:])
    def symbol(self, items):
        return str(items[0])
    def typeparam(self, items):
        return items[0]

    # primitive types
    def string(self, items):
        return items[0][1:-1]
    def list(self, items):
        return list(items)
    def float(self, items):
        return float(items[0])
    def integer(self, items):
        return int(items[0])
    def bool(self, items):
        return bool(items[0])
    def null(self, items):
        return None
    def object(self, items):
        return items[0]

jp = lark.Lark(r"""
    object: obj
         | string
         | float
         | integer
         | bool
         | null
    type : symbol "." symbol ["{" [typeparam ("," typeparam)*] "}"]
    symbol : /[^\W0-9]\w*/
    typeparam: type
         | integer
         | float
         | bool
         | null

    obj : "[" type "," list "," list "]"
    list : "[" [object ("," object)*] "]"

    string : ESCAPED_STRING
    float : SIGNED_FLOAT
    integer : INT
    bool : "true" | "false"
    null : "null"

    %import common.ESCAPED_STRING
    %import common.INT
    %import common.SIGNED_FLOAT
    %import common.WS
    %ignore WS
""", start='object', parser='lalr', transformer=JugsawTransformer())

res = jtp.parse("""Base.Array{Core.Float64, 1}""")
print(res)
assert res == JugsawType("Base", "Array", [JugsawType("Core", "Float64", None), 1])

res = jp.parse("""
        [Jugsaw.People{Core.Int}, [32], ["age"]]
        """)
print(res)
assert res == JugsawObject(JugsawType("Jugsaw", "People", [JugsawType("Core", "Int", "None")]), [32], ["age"])
res = jp.parse("""
        [Jugsaw.TP, [], []]
        """)
print(res)
pdb.set_trace()
