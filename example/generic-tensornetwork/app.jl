using Jugsaw, Jugsaw.JugsawIR, Jugsaw.JugsawIR.JSON3
using GenericTensorNetworks
using GenericTensorNetworks: AbstractProperty
import GenericTensorNetworks.Graphs
using GenericTensorNetworks.Random

JSON3.StructTypes.StructType(::Type{<:Max2Poly}) = JSON3.StructTypes.Struct()
JSON3.StructTypes.StructType(::Type{<:Tropical}) = JSON3.StructTypes.Struct()
JSON3.StructTypes.StructType(::Type{<:CountingTropical}) = JSON3.StructTypes.Struct()

abstract type GraphProblemConfig end
Base.@kwdef struct IndependentSetConfig <: GraphProblemConfig
    graph::JugsawIR.Graph
    weights::Vector{Int}=ones(nv(g))
    openvertices::Vector{Int}=Int[]
    fixedvertices::Dict{Int,Int}=Dict{Int, Int}()
end

function cast_to_problem(c::IndependentSetConfig, optimizer)
    # construct the SimpleGraph.
    g = Graphs.SimpleGraph(c.graph.nv)
    for k in 1:size(c.graph.edges, 2)
        Graphs.add_edge!(g, c.graph.edges[:, k]...)
    end
    # weights
    weights = c.weights == ones(Int, Graphs.nv(g)) ? GenericTensorNetworks.NoWeight() : c.weights
    return IndependentSet(g; weights, optimizer)
end
struct ConfigsMaxSample{K} <: AbstractProperty
    n::Int
end
struct ConfigsMinSample{K} <: AbstractProperty
    n::Int
end
struct ConfigsAllSample <: AbstractProperty
    n::Int
end
pretype(::ConfigsAllSample) = ConfigsAll(; tree_storage=true)
pretype(::ConfigsMaxSample{K}) where K = ConfigsMax(K; tree_storage=true)
pretype(::ConfigsMinSample{K}) where K = ConfigsMin(K; tree_storage=true)
# TODO: support optimizer picker.

"""
```math
x^2
```
"""
function solve(probconfig::GraphProblemConfig,
                property::AbstractProperty;
                usecuda::Bool=false,
                seed::Int=2,
                )
    Random.seed!(seed)
    optimizer=TreeSA(; niters=5)
    problem = cast_to_problem(probconfig, optimizer)
    if property isa ConfigsAllSample
        res = GenericTensorNetworks.solve(problem, pretype(property); usecuda)[]
        return generate_samples(res, num_samples)
    elseif property isa ConfigsMaxSample || property isa ConfigsMinSample
        res = GenericTensorNetworks.solve(problem, pretype(property); usecuda)[]
        return generate_samples(hasfield(res, :coeffs) ? res.coeffs[1] : res.c, num_samples)
    else
        return GenericTensorNetworks.solve(problem, property; usecuda)[]
    end
end

function smallgraph(s::Symbol)
    g = Graphs.smallgraph(s)
    return JugsawIR.Graph(Graphs.nv(g), hcat(collect.(Tuple.(Graphs.edges(g)))...))
end
# :MaximalIS, :SpinGlass, :Coloring, :DominatingSet,
# :HyperSpinGlass, :Matching, :MaxCut, :OpenPitMining,
# :PaintShop, :Satisfiability, :SetCovering, :SetPacking
for (property, tag) in [(:(SizeMax()), :sizemax),
                         (:(CountingMax()), :countingmax),
                         (:(CountingMax(2)), :countingmax2)
                        ]
    FNAME = Symbol(:solve_, tag)
    @eval $FNAME(config; kwargs...) = solve(config, $property; kwargs...)
    @eval @register GenericTN $FNAME(
            IndependentSetConfig(; graph=smallgraph(:petersen), weights=ones(10));
            usecuda::Bool=false,
            seed::Int=2
        )
end
@register GenericTN smallgraph(:petersen)
