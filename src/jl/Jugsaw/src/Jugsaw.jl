module Jugsaw

export serve, register

using HTTP
using JSON3

const ACTORS = Dict{String,Any}()

const ACTIVE_ACTORS = Dict{String,Dict{String,Any}}()

function register(f::Any, name::String)
    ACTORS[name] = f
end

function act(req::HTTP.Request)
    ps = HTTP.getparams(req)
    atype = ps["actor_type_name"]
    aid = ps["actor_id"]
    if haskey(ACTORS, atype)
        f = ACTORS[atype]
        actors = get!(ACTIVE_ACTORS, atype) do
            Dict{String,Any}()
        end
        actor = get!(actors, aid) do
            f()
        end
        arg = JSON3.read(req.body)
        actor(arg)
    else
    end
end

function remove(req)
end


const ROUTER = HTTP.Router()

HTTP.register!(ROUTER, "GET", "/healthz", _ -> JSON3.write((; status="OK")))
HTTP.register!(ROUTER, "GET", "/dapr/config", _ -> JSON3.write((; entities=collect(keys(ACTORS)))))
HTTP.register!(ROUTER, "PUT", "/actors/{actor_type_name}/{actor_id}/method/{method_name}", act)
HTTP.register!(ROUTER, "DELETE", "/actors/{actor_type_name}/{actor_id}", remove)

greet(x::String="Jugsaw") = "Hello, $(x)!"

function serve()
    register(() -> greet, "greet")
    HTTP.serve(ROUTER)
end

end # module
