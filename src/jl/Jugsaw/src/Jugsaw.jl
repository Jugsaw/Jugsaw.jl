module Jugsaw

import JugsawIR
using UUIDs
using UUIDs: uuid4
using HTTP
using JugsawIR.JSON
using Distributed: Future
using MLStyle
using TOML

using JSON3
using URIs

export AppSpecification
export serve, @register
export build
export App

include("typeuniverse.jl")
include("config.jl")
include("common.jl")
include("register.jl")
include("server.jl")
include("client.jl")
include("template.jl")

end # module
