module Jugsaw

using JugsawIR
using JugsawIR.JSON3, JugsawIR.DocStringExtensions
using JugsawIR: @match, Tree, Call, unpack_call, unpack_fields, unpack_list, unpack_object, unpack_typename
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

const GLOBAL_CONFIG = Dict{String, Any}(
    "host" => get(ENV, "JUGSAW_HOST", "http://0.0.0.0"),
    "port" => get(ENV, "JUGSAW_PORT", 8088)
)
function get_endpoint()
    return """$(GLOBAL_CONFIG["host"]):$(GLOBAL_CONFIG["port"])"""
end

include("errors.jl")
include("register.jl")
include("clientcode.jl")
include("server/server.jl")
include("client/Client.jl")
include("template.jl")
include("checkapp.jl")

end # module
