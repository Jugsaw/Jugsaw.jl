module Jugsaw

using JugsawIR
using JugsawIR.JSON3, JugsawIR.DocStringExtensions
using JugsawIR: @match, Tree, Call, unpack_call, unpack_fields, unpack_list, unpack_object, unpack_typename
using UUIDs
using UUIDs: uuid4
using HTTP
using Distributed: Future
using TOML
using JSON3

export AppSpecification, AppRuntime
export serve, @register
export build
export NoDemoException
export generate_code

include("config.jl")
include("errors.jl")
include("register.jl")
include("clientcode.jl")
include("server/server.jl")
include("client/Client.jl")
include("template.jl")

end # module
