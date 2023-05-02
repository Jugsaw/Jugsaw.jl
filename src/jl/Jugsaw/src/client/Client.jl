module Client

using JugsawIR
using JugsawIR: type2str, TypeTable, JSON3
using JugsawIR.Lerche
using MLStyle
using HTTP
using URIs
using JugsawIR.AbstractTrees
using OrderedCollections: OrderedDict
using Markdown

export App
export RemoteHandler, LocalHandler, request_app, @call
export request_app, fetch, call, request_app, healthz, dapr_config, delete, test_demo, @test_demo

include("Core.jl")
include("parser.jl")
include("remotecall.jl")

end