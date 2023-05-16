using Test, Jugsaw
using JugsawIR

@testset "module and symbol" begin
    #m, s = Jugsaw.module_and_symbol(Jugsaw.protect_type(Dict))
    m, s = Jugsaw.module_and_symbol(Dict)
    @test m === Base
    @test s == :Dict
end

@testset "multi function" begin
    smallgraph(sym::Symbol) = sym
    app = AppSpecification(:testapp)
    @register app collect(1:10)
    @register app collect(1:3)
    @register app smallgraph(:petersen)
    t = 1.0:0.1:2
    @register app collect(t) == ones(Int, 10)
    @test Jugsaw.nfunctions(app) == 4
    @test Jugsaw.length(app.method_demos["collect"]) == 2
    @test Jugsaw.selftest(app)[1]
    @test Jugsaw.match_demo("collect", (1:4,), (;), app).fcall.args == (1:10,)
    adt, = JugsawIR.julia2adt(app.method_demos["collect"][1].fcall)
    @test Jugsaw.match_demo_or_throw(adt, app).fcall.args == (1:10,)
    adt = JugsawIR.ir2adt(JugsawIR.julia2ir(app.method_demos["smallgraph"][1].fcall)[1])
    @show adt
    @test Jugsaw.match_demo_or_throw(adt, app).fcall.args == (:petersen,)
    adt, = JugsawIR.julia2adt(JugsawIR.Call(collect, ([1,2],), (;)))
    @test_throws NoDemoException Jugsaw.match_demo_or_throw(adt, app)
end