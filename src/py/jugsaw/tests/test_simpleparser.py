from jugsaw import jtp, jp, JugsawType, JugsawObject, Symbol

def test_jtp():
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

    res = jtp.parse("Jugsaw.JugsawFunctionCall{Main.#solve, Core.Tuple{Main.IndependentSetConfig, GenericTensorNetworks.CountingMax{2}}, Core.NamedTuple{(:usecuda, :seed), Core.Tuple{Core.Bool, Core.Int64}}}")
    assert isinstance(res, JugsawType)
    print(res)

def test_nested_mod():
    res = jtp.parse("""Core.AnyMod.Tuple{}""")
    assert res == JugsawType("Core.AnyMod", "Tuple", [])
    print(res)

def test_jp():
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