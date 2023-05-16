module Jugsaw

using JugsawIR
using JugsawIR.JSON3
using JugsawIR: @match, Tree, Call
using UUIDs
using UUIDs: uuid4
using HTTP
using Distributed: Future
using TOML

export AppSpecification, AppRuntime
export serve, @register
export build
export NoDemoException

include("typeuniverse.jl")
include("errors.jl")
include("config.jl")
include("common.jl")
include("register.jl")
include("server.jl")
include("client/Client.jl")
include("template.jl")
include("checkapp.jl")
include("clientcode.jl")

end # module
