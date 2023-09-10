using Test, Jugsaw
using JugsawIR

@testset "multi function" begin
    app = Jugsaw.APP; empty!(app)
    smallgraph(sym::Symbol) = sym
    @register testapp collect(1:10)
    @register testapp collect(1:3)
    @register testapp smallgraph(:petersen)
    t = 1.0:0.1:2
    @register testapp collect(t) == ones(Int, 10)
    @test Jugsaw.nfunctions(app) == 3
    @test app.method_demos["collect"] isa Jugsaw.JugsawDemo
    @test Jugsaw.selftest(app)[1]
end