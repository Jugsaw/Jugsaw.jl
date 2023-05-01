module Jugsaw

using JugsawIR
using UUIDs
using UUIDs: uuid4
using HTTP
using Distributed: Future
using MLStyle
using TOML

export AppSpecification
export serve, @register
export build

include("typeuniverse.jl")
include("config.jl")
include("common.jl")
include("register.jl")
include("server.jl")
include("client/Client.jl")
include("template.jl")

end # module
