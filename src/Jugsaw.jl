module Jugsaw

using JugsawIR
using JugsawIR.JSON3, JugsawIR.DocStringExtensions
using MLStyle: @match
using UUIDs
using UUIDs: uuid4
using HTTP
using Distributed: Future
using TOML

export AppSpecification, AppRuntime
export serve, @register
export build
export NoDemoException

include("config.jl")
include("errors.jl")
include("register.jl")
include("server/server.jl")
include("client/Client.jl")
include("template.jl")

end # module
