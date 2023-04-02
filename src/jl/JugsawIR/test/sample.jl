using GenericTensorNetworks
using GenericTensorNetworks.OMEinsum
using GenericTensorNetworks.OMEinsum.OMEinsumContractionOrders
using JugsawIR
using Graphs
using Base: TwicePrecision

# st = json4(Polynomial([2,3,5.0]))
# parse4(st; mod=Main)

# app = JugsawIR.AppSpecification("test")
# JugsawIR.register!(app, random_diagonal_coupled_graph, (2, 3, 0.6), NamedTuple())
# js = json4(app)
# res = parse4(js; mod=Main)

app = @register gtn begin
    solve(IndependentSet(smallgraph(:petersen)::SimpleGraph{Int}; optimizer=TreeSA(; niters::Int=5)), SizeMax())::TropicalF64
end
js = json4(app)
res = parse4(js; mod=Main)["__main__"];
fv = res.method_demos[2].second["fixedvertices"];