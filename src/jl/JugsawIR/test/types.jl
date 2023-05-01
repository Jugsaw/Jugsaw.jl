using Test, JugsawIR

@testset "JugsawFunctionCall and JugsawDemo" begin
    jf = JugsawFunctionCall(isapprox, (1.0, 1.0001), (; atol=1e-2))
    println(jf)
    @test feval(jf)
    @test !feval(jf, 1.0, 1.2)
    str, types = json4(jf)
    loaded = parse4(str, jf)
    @test loaded == jf
    @test function_signature(loaded) == "JugsawIR.JugsawFunctionCall{Base.#isapprox, Core.Tuple{Core.Float64, Core.Float64}, Core.NamedTuple{(:atol,), Core.Tuple{Core.Float64}}}"
    @show function_signature(loaded)
    @test feval(loaded)

    demo = JugsawDemo(jf, feval(jf), "test")
    str, types = json4(demo)
    ld = parse4(str, demo)
    println(ld)
    @test ftest(ld)
end