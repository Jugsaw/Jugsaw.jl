using Test, JugsawIR
using JSON3
using JugsawIR: test_twoway

obj_demos = [
    (2.0, 3.0),
    (3, 5),
    (2f0, 4f0),
    (3+2im, 4-3im),
    ("x", "zz"),
    (nothing, nothing),
    (true, false),
    (false, true),
    (:x, :y),
    (UInt8(3), UInt8(1)),
    ('x', 'y'),
    (missing, missing),
    ((1, '2'), (3, '4')),
    ([1, 2, 3], [0]),
    ([1+2im, 2+3im], [2+3im]),
    ((; x=4, y=5), (; x=6, y=7)),
    (Dict(2=>3), Dict(5=>2, 4=>3)),
    (Dict(:s=>3), Dict(:x=>5, :z=>6)),
    (Graph(4), Graph(6)),
    ((; complex=1+2im,
            Tensor= SizedArray(randn(3,3)),
            Graph = Graph(6, [2 4 1; 3 1 6]),
            ),
    (; complex=3+2im,
                Tensor= SizedArray(randn(4,3)),
                Graph = Graph(9, [2 6 1; 3 1 6]),
                ),

            ),
    # extended types
    (SizedArray(randn(3, 3)), SizedArray(randn(8, 8))),
    (Base64Array(randn(3, 3)), Base64Array(randn(8, 8))),
    (Graph(5, rand(1:5, 2, 10)), Graph(8, rand(1:5, 2, 16))),
    ]

# typed parse
@testset "julia2adt" begin
    for (obj, demo) in obj_demos
        @info typeof(obj)
        @test test_twoway(obj, demo)
    end
    @testset "datatype" begin
        type = TypeSpec(ComplexF64)
        @test type.name == "Base.Complex{Core.Float64}"
        @test type.fieldnames == ["re", "im"]
        @test getfield.(type.fieldtypes, :name) == ["Core.Float64", "Core.Float64"]
        @test type.description == "```\nComplex{T<:Real} <: Number\n```\n\nComplex number type with real and imaginary part of type `T`.\n\n`ComplexF16`, `ComplexF32` and `ComplexF64` are aliases for `Complex{Float16}`, `Complex{Float32}` and `Complex{Float64}` respectively.\n\nSee also: [`Real`](@ref), [`complex`](@ref), [`real`](@ref).\n"
    end
end

@testset "typespec" begin
    typespec = TypeSpec(Graph)
    @test JSON3.write(typespec) isa String
end

@testset "Call" begin
    demo = Call(sin, (0.5,), (;))
    s = JugsawIR.write_object(demo)
    obj = JugsawIR.read_object(s, demo)
    @test obj == demo
end