using Test, JugsawIR

@testset "Call and JugsawDemo" begin
    jf = JugsawIR.Call(isapprox, (1.0, 1.0001), (; atol = 1e-2))
    println(jf)
    @test fevalself(jf)
    @test !feval(jf, 1.0, 1.2)
    str = JugsawIR.write_object(jf)
    loaded = JugsawIR.read_object(str, jf |> typeof)
    @test loaded == jf
    @test fevalself(loaded)

    demo = JugsawDemo(jf, fevalself(jf), Dict("docstring"=>"test"))
    str = JugsawIR.write_object(demo)
    ld = JugsawIR.read_object(str, demo |> typeof)
    println(ld)
    @test ftest(ld)

    jf = JugsawIR.Call(isapprox, (JugsawIR.Call(sin, (2.0,), (;)), 0.9092974268256817), (; atol=JugsawIR.Call(x->x/10, (1e-2,), (;))))
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

