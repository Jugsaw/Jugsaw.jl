using Test, Jugsaw
using JugsawIR

@testset "multi function" begin
    app = Jugsaw.APP; empty!(app)
    smallgraph(sym::Symbol) = sym
    @test_throws ErrorException @register testapp collect(1:10)
    @register testapp collect([1,2,3])
    @register testapp smallgraph(:petersen)
    @test Jugsaw.nfunctions(app) == 2
    @test app.method_demos["collect"] isa Jugsaw.JugsawDemo
    @test Jugsaw.selftest(app)[1]
end