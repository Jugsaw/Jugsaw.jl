using JugsawIR: jp, tree2adt, JugsawExpr
using JugsawIR.Lerche
using Test

@testset "object" begin
    res = Lerche.parse(jp, """["object", "Jugsaw.People{Core.Int}", 32]""")
    @test tree2adt(res) == JugsawExpr(:object, ["Jugsaw.People{Core.Int}", 32])
    res = Lerche.parse(jp, """['object', "Jugsaw.TP"]""")
    @test tree2adt(res) == JugsawExpr(:object, ["Jugsaw.TP"])
    res = Lerche.parse(jp, """["untyped"]""")
    @test tree2adt(res) == JugsawExpr(:untyped, [])

    res = Lerche.parse(jp, """['call', "f", ['untyped', 3], ['untyped', "x"]]""")
    @test tree2adt(res) == JugsawExpr(:call, ["f", JugsawExpr(:untyped, [3]), JugsawExpr(:untyped, ["x"])])

    res = Lerche.parse(jp, """['list', 2, ['list', "x"]]""")
    @test tree2adt(res) == JugsawExpr(:list, [2, JugsawExpr(:list, ["x"])])
end