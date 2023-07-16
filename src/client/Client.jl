module Client

using JugsawIR
using JugsawIR: type2str, TypeTable, JSON3
using JugsawIR.Lerche, JugsawIR.DocStringExtensions
using MLStyle
using HTTP
using JugsawIR.AbstractTrees
using OrderedCollections: OrderedDict
using Markdown
using UUIDs

export ClientContext, App, DemoRef, Demo
export request_app, fetch, call, run_demo, request_app, healthz, test_demo

include("Core.jl")
include("parser.jl")
include("remotecall.jl")

end