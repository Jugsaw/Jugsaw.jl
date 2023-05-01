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

include("app.jl")
include("parser.jl")

end