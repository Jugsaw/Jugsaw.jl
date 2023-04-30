using JugsawIR: json4, parse4
using JSON
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

@testset "json4" begin
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
    # typed parse
    for (obj, demo) in [
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
        @info typeof(obj)
        str, typestr = json4(obj)
        sT = JugsawIR.type2str(typeof(obj))
        types = JugsawIR.Lerche.parse(JugsawIR.jp, typestr)
        @show sT# ∈ types.names
        @show types
        @show types.defs[sT]
        res = parse4(str, demo)
        @test obj === res || obj == res
    end
end