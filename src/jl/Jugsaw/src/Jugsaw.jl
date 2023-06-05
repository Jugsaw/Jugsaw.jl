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
export generate_code

include("typeuniverse.jl")
include("errors.jl")
include("register.jl")
include("clientcode.jl")
include("server/server.jl")
include("client/Client.jl")
include("template.jl")
include("checkapp.jl")

end # module
