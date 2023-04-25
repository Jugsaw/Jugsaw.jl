using Lerche, Test

@testset "type" begin
    jtp = Lark(read(joinpath(@__DIR__, "../src/jugsawir.lark"), String),parser="lalr",lexer="contextual", start="type")
    res = Lerche.parse(jtp, """Base.Array{Core.Float64, 1}""")
    print(res)
    #@test res == JugsawType("Base", "Array", [JugsawType("Core", "Float64", None), 1])

    res = Lerche.parse(jtp, """Base.Array{true, 1}""")
    print(res)
    #@test res == JugsawType("Base", "Array", [True, 1])

    res = Lerche.parse(jtp, """Core.Tuple{}""")
    print(res)
    #@test res == JugsawType("Core", "Tuple", [])

    res = Lerche.parse(jtp, """Base.Array{Core.Float64, (:x, :y)}""")
    print(res)
    #@test res == JugsawType("Base", "Array", [JugsawType("Core", "Float64", None), (Symbol("x"), Symbol("y"))])

    res = Lerche.parse(jtp, "Jugsaw.JugsawFunctionCall{Main.#solve, Core.Tuple{Main.IndependentSetConfig, GenericTensorNetworks.CountingMax{2}}, Core.NamedTuple{(:usecuda, :seed), Core.Tuple{Core.Bool, Core.Int64}}}")
    print(res)
    #@test isa(res, JugsawType)
end

@testset "object" begin
    jp = Lark(read(joinpath(@__DIR__, "../src/jugsawir.lark"), String),parser="lalr",lexer="contextual", start="object")
    res = Lerche.parse(jp, """
            {"type" : "Jugsaw.People{Core.Int}", "values" : [32], "fields" : ["age"]}
            """)
    print(res)
    #@test res == JugsawObject(JugsawType("Jugsaw", "People", [JugsawType("Core", "Int", None)]), [32], ["age"])
    res = Lerche.parse(jp, """
            {"type":"Jugsaw.TP", "values":[], "fields":[]}
            """)
    print(res)
    #@test res == JugsawObject(JugsawType("Jugsaw", "TP", None), [], [])
end