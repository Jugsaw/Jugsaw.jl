module Client

using JugsawIR
using JugsawIR: type2str, TypeTable, JSON3
using JugsawIR.Lerche
using MLStyle
using HTTP
using JugsawIR.AbstractTrees
using OrderedCollections: OrderedDict
using Markdown
using UUIDs

export App, DemoRefs, DemoRef, Demo
export RemoteHandler, LocalHandler, request_app
export request_app, fetch, call, run_demo, request_app, healthz, dapr_config, delete, test_demo, test_demos

include("Core.jl")
include("parser.jl")
include("remotecall.jl")

end