using Test, JugsawIR

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