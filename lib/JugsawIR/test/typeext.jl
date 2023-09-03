module TestJugsawIR
using Test, JugsawIR
using JSON3
using JugsawIR: test_twoway

struct GraphT
    nv::Int
    edges::Matrix{Int}
    function GraphT(nv::Int, edges::Matrix{Int})
        new(nv, edges)
    end
    function GraphT(nv::Int)
        new(nv, zeros(Int, 2, 0))
    end
end
Base.:(==)(g1::GraphT, g2::GraphT) = g1.nv == g2.nv && g1.edges == g2.edges
JSON3.StructTypes.StructType(::Type{GraphT}) = JSON3.StructTypes.CustomStruct()
JSON3.StructTypes.lower(x::GraphT) = (x.nv, vec(x.edges))
JSON3.StructTypes.lowertype(::Type{GraphT}) = Tuple{Int, Vector{Int}}
JSON3.StructTypes.construct(::Type{GraphT}, x) = GraphT(x[1], reshape(x[2], 2, :))

obj_demos = [
    (2.0, 3.0),
    (3, 5),
    (2f0, 4f0),
    (SizedArray(randn(3, 3)), SizedArray(randn(8, 8))),
    (3+2im, 4-3im),
    ("x", "zz"),
    (nothing, nothing),
    (true, false),
    (false, true),
    (:x, :y),
    (UInt8(3), UInt8(1)),
    ('x', 'y'),
    (missing, missing),
    #(undef, undef),
    #(1:3, 2:6),
    #(1:0.01:2, 1:0.03:4.0),
    #(Int, Int),
    #(Union{}, Union{}),
    #(Union{Integer, Float64}, Union{Integer, Float64}),
    #(Array{Float64}, Array{Float64}),
    #(Array{Int,2},Array{Int,2}),
    ((1, '2'), (3, '4')),
    ([1, 2, 3], [0]),
    ([1+2im, 2+3im], [2+3im]),
    ((; x=4, y=5), (; x=6, y=7)),
    (Dict(2=>3), Dict(5=>2, 4=>3)),
    (Dict(:s=>3), Dict(:x=>5, :z=>6)),
    (GraphT(4), GraphT(6)),
    #(JugsawIR.Call(isapprox, (2.0, 2.001), (;atol =1e-2)), JugsawIR.Call(isapprox, (2.00001, 2.0000), (; atol=1e-3))),
    ((; complex=1+2im,
            Tensor= SizedArray(randn(3,3)),
            Graph = GraphT(6, [2 4 1; 3 1 6]),
            ),
    (; complex=3+2im,
                Tensor= SizedArray(randn(4,3)),
                Graph = GraphT(9, [2 6 1; 3 1 6]),
                ),

            )
    ]

# typed parse
@testset "julia2adt" begin
    for (obj, demo) in obj_demos
        @info typeof(obj)
        @test test_twoway(obj, demo)
    end
    @testset "datatype" begin
        type = JDataType(ComplexF64)
        @test type.name == "Base.Complex{Core.Float64}"
        @test type.fieldnames == ["re", "im"]
        @test type.fieldtypes == ["Core.Float64", "Core.Float64"]
        @test type.meta["docstring"] == "```\nComplex{T<:Real} <: Number\n```\n\nComplex number type with real and imaginary part of type `T`.\n\n`ComplexF16`, `ComplexF32` and `ComplexF64` are aliases for `Complex{Float16}`, `Complex{Float32}` and `Complex{Float64}` respectively.\n\nSee also: [`Real`](@ref), [`complex`](@ref), [`real`](@ref).\n"
    end
end

end