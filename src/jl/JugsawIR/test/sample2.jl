using GenericTensorNetworks
using GenericTensorNetworks: AbstractProperty
using GenericTensorNetworks.OMEinsum
using GenericTensorNetworks.OMEinsum.OMEinsumContractionOrders
using JugsawIR
using Graphs
using Base: TwicePrecision
using Random
using JSON

# TODO: we need to support SELECT better! Maybe automatically categorize functions.

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

graph = JugsawIR.Graph(10, hcat(collect.(Tuple.(edges(smallgraph(:petersen))))...))
#, :MaximalIS, :SpinGlass, :Coloring, :DominatingSet,
#:HyperSpinGlass, :Matching, :MaxCut, :OpenPitMining, :PaintShop, :Satisfiability, :SetCovering, :SetPacking]
app = AppSpecification("gtn")
for property in [:(SizeMax()), :(CountingMax()), :(CountingMax(2))]
    @eval @register app solve(IndependentSetConfig(; graph=graph, weights=ones(10)), $property;
            usecuda::Bool=false,
            seed::Int=2,
            optimizer=TreeSA()
        )
end

open(joinpath(@__DIR__, "method_table.config"), "w") do f
    write(f, json4(app))
end
#res = parse4(js; mod=Main)["__main__"];
for i=1:length(app.method_demos)
    @show i
    # client side: convert to json4
    js = json4(app.method_demos[i].first)

    # server side: 1. convert string to Dict
    data = JSON.parse(js)["__main__"]
    # server side: 2. convert dict to `JugsawFunctionCall` type
    @show data
    k = JugsawIR.find_method(data, app)
    @show k
    @assert k == i
    method_call = JugsawIR.parsetype(Main, typeof(app.method_demos[k].first), data)
    @show method_call
    @show JugsawIR.run(Main, method_call)
end