module TestJugsawIR
using JugsawIR: julia2adt, adt2julia
using Test, JugsawIR
using JugsawIR: test_twoway

struct GraphT
    nv::Int
    edges::Matrix{Int}
    function GraphT(nv::Int, edges::Matrix{Int})
        new(nv, edges)
    end
    function GraphT(nv::Int)
        new(nv)
    end
end
@enum ENM e1 e2 e3
Base.:(==)(g1::GraphT, g2::GraphT) = g1.nv == g2.nv && g1.edges == g2.edges

obj_demos = [
    (2.0, 3.0),
    (3, 5),
    (2f0, 4f0),
    (randn(3, 3), randn(8, 8)),
    (3+2im, 4-3im),
    ("x", "zz"),
    (nothing, nothing),
    (true, false),
    (false, true),
    (:x, :y),
    (UInt8(3), UInt8(1)),
    (Int, Int),
    ('x', 'y'),
    (missing, missing),
    (undef, undef),
    (1:3, 2:6),
    (1:0.01:2, 1:0.03:4.0),
    (e2, e3),
    (Union{}, Union{}),
    (Union{Integer, Float64}, Union{Integer, Float64}),
    (Array{Float64}, Array{Float64}),
    (Array{Int,2},Array{Int,2}),
    ((1, '2'), (3, '4')),
    ([1, 2, 3], [0]),
    ([1+2im, 2+3im], [2+3im]),
    ((; x=4, y=5), (; x=6, y=7)),
    (Dict(2=>3), Dict(5=>2, 4=>3)),
    (Dict(:s=>3), Dict(:x=>5, :z=>6)),
    (GraphT(4), GraphT(6)),
    (JugsawIR.Call(isapprox, (2.0, 2.001), (;atol =1e-2)), JugsawIR.Call(isapprox, (2.00001, 2.0000), (; atol=1e-3))),
    ((; complex=1+2im,
            Tensor= randn(3,3),
            Graph = GraphT(6, [2 4 1; 3 1 6]),
            ),
    (; complex=3+2im,
                Tensor= randn(4,3),
                Graph = GraphT(9, [2 6 1; 3 1 6]),
                ),

            )
    ]

# typed parse
@testset "julia2adt" begin
    for (obj, demo) in obj_demos
        @info typeof(obj)
        @test test_twoway(obj, demo)
        if !(typeof(obj) <: JugsawIR.DirectlyRepresentableTypes || obj === undef || obj isa Union{DataType, Array, Dict, Enum, UnionAll})
            sT = JugsawIR.type2str(typeof(obj))
            adt, = julia2adt(obj)
            @test adt.typename == sT
        end
    end

    @testset "datatype" begin
        type, tt = julia2adt(ComplexF64)
        @test type == JugsawADT.Object("JugsawIR.JDataType", ["Base.Complex{Core.Float64}",
            JugsawADT.Vector(["re", "im"]), JugsawADT.Vector(["Core.Float64", "Core.Float64"])])
        println(tt)
    end
end

@testset "get fieldnames" begin
    obj = (; complex=1+2im,
            Tensor= randn(3,3),
            Graph = GraphT(6, [2 4 1; 3 1 6]),
            )
    adt, typeadt = julia2adt(obj)
    tt = adt2julia(typeadt, JugsawIR.demoof(TypeTable))
    @test tt isa TypeTable
    @show tt
    @test JugsawIR.get_fieldnames(adt, tt) == ["complex", "Tensor", "Graph"]
end

end