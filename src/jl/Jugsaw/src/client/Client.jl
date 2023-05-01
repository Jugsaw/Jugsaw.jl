module Client

using JugsawIR
using JugsawIR: type2str, TypeTable
using JugsawIR.Lerche
using MLStyle
using HTTP
using URIs
using JugsawIR.AbstractTrees
using OrderedCollections: OrderedDict

export App

include("parser.jl")
include("app.jl")

end