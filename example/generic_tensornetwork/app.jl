using Jugsaw
using Jugsaw.Universe

using GenericTensorNetworks
using GenericTensorNetworks: AbstractProperty
import Graphs
using Random

# TODO: we need to support SELECT better! Maybe automatically categorize functions.

abstract type GraphProblemConfig end
Base.@kwdef struct IndependentSetConfig <: GraphProblemConfig
    graph::Graph
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
    weights = c.weights == ones(Int, Graphs.nv(g)) ? GenericTensorNetworks.NoWeight() : weights
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
function solve(probconfig::GraphProblemConfig,
                property::AbstractProperty;
                usecuda::Bool=false,
                seed::Int=2,
                optimizer=TreeSA()
                )
    Random.seed!(seed)
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

graph = Graph(10, hcat(collect.(Tuple.(Graphs.edges(Graphs.smallgraph(:petersen))))...))
#, :MaximalIS, :SpinGlass, :Coloring, :DominatingSet,
#:HyperSpinGlass, :Matching, :MaxCut, :OpenPitMining, :PaintShop, :Satisfiability, :SetCovering, :SetPacking]
app = Jugsaw.AppSpecification("generic-tensor-network")
for property in [:(SizeMax()), :(CountingMax()), :(CountingMax(2))]
    @eval @register app solve(IndependentSetConfig(; graph=graph, weights=ones(10)), $property;
            usecuda::Bool=false,
            seed::Int=2,
            optimizer=TreeSA()
        )
end

#####

r= Jugsaw.AppRuntime(app)
serve(r, @__DIR__)