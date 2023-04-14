using Test
using JugsawIR: json4, parse4
using JugsawIR
using JSON

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

@testset "json4" begin
    struct GraphT
        nv::Int
        edges::Matrix{Int}
    end
    Base.:(==)(g1::GraphT, g2::GraphT) = g1.nv == g2.nv && g1.edges == g2.edges
    # typed parse
    for obj in [
        2.0, 3, 2f0, 3+2im, "x", nothing, true, :x, UInt8(3),
        Int,
        1:3,
        1:0.01:2,
        Union{},
        Union{Integer, Float64},
        Array{Float64},
        Array{Int,2},
        (1, 2), [1, 2, 3], [1+2im, 2+3im], (; x=4, y=5),
        Dict(2=>3),
        Dict(:s=>3),
         Dict("complex"=>1+2im,
             "Tensor"=> randn(3,3),
             "Graph" => GraphT(6, [2 4 1; 3 1 6]),
             )
        ]
        @info typeof(obj)
        str = json4(obj)
        if !(obj isa Type)
            res = parse4(str; mod=@__MODULE__)
            @test obj == res
        end
        res = parse4(str; type=typeof(obj), mod=@__MODULE__)
        @test obj == res
    end
end

@testset "type" begin
    T = typeof((
        2.0, 3, 2f0, 3+2im, "x", nothing, true, :x, UInt8(3),
        (1, 2), [1, 2, 3], [1+2im, 2+3im], (; x=4, y=5),
        Int,
         Dict("complex"=>1+2im,
             "Tensor"=> randn(3,3),
             "Graph" => Graph(6, [2 4 1; 3 1 6]),
             )
        ))
    res = jsontype4(T)
    @test res isa String
end
