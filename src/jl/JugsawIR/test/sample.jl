using GenericTensorNetworks
using JugsawIR

st = json4(Polynomial([2,3,5.0]))
parse4(st; mod=Main)

app = JugsawIR.AppSpecification("test")
JugsawIR.register!(app, random_diagonal_coupled_graph, (2, 3, 0.6), NamedTuple())
js = json4(app)
parse4(js)

using Graphs
graph = smallgraph(:petersen)
register(solve, graph, problem, )