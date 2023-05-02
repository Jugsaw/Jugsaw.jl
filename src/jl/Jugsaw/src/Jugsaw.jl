module Jugsaw

using JugsawIR
using JugsawIR.JSON3
using JugsawIR: @match, Tree
using UUIDs
using UUIDs: uuid4
using HTTP
using Distributed: Future
using TOML

export AppSpecification, AppRuntime
export serve, @register
export build

include("typeuniverse.jl")
include("config.jl")
include("common.jl")
include("register.jl")
include("server.jl")
include("client/Client.jl")
include("template.jl")
include("checkapp.jl")

end # module
