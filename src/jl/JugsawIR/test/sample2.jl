using GenericTensorNetworks
using GenericTensorNetworks: AbstractProperty
using GenericTensorNetworks.OMEinsum
using GenericTensorNetworks.OMEinsum.OMEinsumContractionOrders
using JugsawIR
using Graphs
using Base: TwicePrecision

# TODO: we need to support SELECT better! Maybe automatically categorize functions.

abstract type GraphProblemConfig end
Base.@kwdef struct IndependentSetConfig <: GraphProblemConfig
    g::Jugsaw.Graph
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
    weights = weights == ones(Int, Graphs.nv(g)) ? GenericTensorNetworks.NoWeight() : weights
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
pretype(::ConfigsMaxSample{K}) = ConfigsMax(K; tree_storage=true)
pretype(::ConfigsMinSample{K}) = ConfigsMin(K; tree_storage=true)
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
        return GenericTensorNetworks.solve(problem, p; usecuda)[]
    end
end

app = AppSpecification(name)
graph = JugsawIR.Graph(10, hcat(collect.(Tuple.(edges(smallgraph(:petersen))))...))
#, :MaximalIS, :SpinGlass, :Coloring, :DominatingSet,
#:HyperSpinGlass, :Matching, :MaxCut, :OpenPitMining, :PaintShop, :Satisfiability, :SetCovering, :SetPacking]
for property in [SizeMax(), CountingMax(), CountingMax(2)]
    @register app solve(IndependentSetConfig(; graph=graph, weights=ones(10)), property;
            usecuda::Bool=false,
            seed::Int=2,
            optimizer=TreeSA()
        )
end


js = json4(app)
res = parse4(js; mod=Main)["__main__"];
fv = res.method_demos[2].second["fixedvertices"];