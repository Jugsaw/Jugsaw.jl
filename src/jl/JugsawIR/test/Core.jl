using Test, JugsawIR

@testset "demoof" begin
    for T in [Int64, String, Tuple{Int64, String}, Vector{Int64}, JugsawIR.TypeTable]
        @test JugsawIR.demoof(T) isa T
    end
end

@testset "JugsawFunctionCall and JugsawDemo" begin
    jf = JugsawIR.Call(isapprox, [1.0, 1.0001], ["atol"], [1e-2])
    println(jf)
    @test fevalself(jf)
    @test !feval(jf, 1.0, 1.2)
    str, types = julia2ir(jf)
    loaded = ir2julia(str, jf)
    @test loaded == jf
    @test fevalself(loaded)

    demo = JugsawDemo(jf, fevalself(jf), Dict("docstring"=>"test"))
    str, types = julia2ir(demo)
    ld = ir2julia(str, demo)
    println(ld)
    @test ftest(ld)

    jf = JugsawIR.Call(isapprox, [JugsawIR.Call(sin, [2.0], [], []), 0.9092974268256817], ["atol"], [JugsawIR.Call(x->x/10, [1e-2], [], [])])
    @test fevalself(jf)
end

@testset "type string" begin
    struct S{T, C}
    end
    for (A, B) in [(ComplexF64, "Base.Complex{Core.Float64}"), (Float64, "Core.Float64"),
                (Array{Float64, 3}, "Core.Array{Core.Float64, 3}"),
                (S{Float64, ComplexF64}, "Main.S{Core.Float64, Base.Complex{Core.Float64}}"),
                (Tuple{}, "Core.Tuple{}")
            ]
        @test JugsawIR.type2str(A) == B
        @test JugsawIR.str2type(@__MODULE__, B) == A
    end
    @test JugsawIR.str2type(@__MODULE__, "Core.UInt8") == UInt8
end

