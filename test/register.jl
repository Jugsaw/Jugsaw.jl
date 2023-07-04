using Test, Jugsaw
using JugsawIR

@testset "module and symbol" begin
    #m, s = Jugsaw.module_and_symbol(Jugsaw.protect_type(Dict))
    m, s = Jugsaw.module_and_symbol(Dict)
    @test m === Base
    @test s == :Dict
end

@testset "multi function" begin
    app = Jugsaw.APP; empty!(app)
    smallgraph(sym::Symbol) = sym
    @register testapp collect(1:10)
    @register testapp collect(1:3)
    @register testapp smallgraph(:petersen)
    t = 1.0:0.1:2
    @register testapp collect(t) == ones(Int, 10)
    @test Jugsaw.nfunctions(app) == 4
    @test Jugsaw.length(app.method_demos["collect"]) == 2
    @test Jugsaw.selftest(app)[1]
    @test Jugsaw.match_demo("collect", (1:4,), (;), app).fcall.args == (1:10,)
end