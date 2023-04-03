export serve, @register

using UUIDs: uuid4
using HTTP
using JSON3
using Distributed: Future

#####
struct StateStore
    store::Dict{String,Future}
end

"""
This is a simple in-memory state store which holds the results from the actor calls.
We may add many different kinds of state store later (local file or Database).
"""
STATE_STORE = StateStore(Dict{String,String}())

Base.setindex!(s::StateStore, v::Future, k) = s.store[k] = v
Base.setindex!(s::StateStore, v, k) = put!(s.store[k], v)
Base.getindex(s::StateStore, k) = s.store[k][]

#####

"""
Describe current status of an actor.
"""
struct Actor{T<:Pair{<:JugsawFunctionCall}}
    # actor is a function demo
    actor::T
    taskref::Ref{Task}
    mailbox::Channel{Message}
end

function Actor(actor)
    taskref = Ref{Task}()
    chnl = Channel{Message}(taskref=taskref) do ch
        for msg in ch
            act(actor, msg)
        end
    end
    Actor(actor, taskref, chnl)
end

Base.close(a::Actor) = close(a.mailbox) # TODO: save actor state to state store

# NOTE: I prefer using a function name, otherwise it is hard to located the function definition.
function put_message(a::Actor, msg::Message)
    # FIXME: no need if we have a state store db
    put!(a.mailbox, msg)
end

function act(actor::Any, msg::Message)
    res = actor.first.fname(msg.request.args...; msg.request.kwargs...)
    # TODO: custom serializer
    s_res = JugsawIR.json4(res)
    STATE_STORE[msg.response.object_id] = s_res
end

#####

const ACTOR_FACTORY = AppSpecification("default")
const ACTORS = Dict{Pair{String,String},Any}()

"""
Try to activate an actor. If the actor of `actor_id` does not exist yet, a new
one is created based on the registered `ActorFactor` of `actor_type`. Note that
the actor may be configured to recover from its lastest state snapshot.
"""
function activate(actor_type::String, actor_id::String)
    if haskey(ACTOR_FACTORY.method_demos, actor_type)
        get!(ACTORS, actor_type => actor_id) do
            Actor(ACTOR_FACTORY.method_demos[actor_type])
        end
    end
end

function act(http::HTTP.Request)
    ps = HTTP.getparams(http)
    # find the correct method
    dict = JSON3.read(http.body)
    function_signature =dict["__type__"]
    a = activate(function_signature, string(ps["actor_id"]))
    # TODO: load actor state from state store
    #req = JSON3.read(http.body, JugsawFunctionCall)
    req = JugsawIR.parsetype(@__MODULE__, typeof(a.actor.first), dict)
    resp = ObjectRef()
    STATE_STORE[resp.object_id] = Future()
    put_message(a, Message(req, resp))
    HTTP.Response(200, JSON3.write(resp))
end

"""
Remove idle actors. Actors may be configure to persistent its current state.
"""
function deactivate(req::HTTP.Request)
    ps = HTTP.getparams(req)
    atype = string(ps["actor_type_name"])
    aid = string(ps["actor_id"])
    actor = get(ACTORS, atype => aid, nothing)
    if !isnothing(actor)
        close(actor)
        delete!(ACTORS, atype => aid)
    end
end

"""
This is just a workaround. In the future, users should fetch results from StateStore directly.
"""
function fetch(req::HTTP.Request)
    ref = JSON3.read(req.body, ObjectRef)
    STATE_STORE[ref.object_id]
end

#####
# Service
#####


const ROUTER = HTTP.Router()

HTTP.register!(ROUTER, "GET", "/healthz", _ -> JSON3.write((; status="OK")))
HTTP.register!(ROUTER, "GET", "/dapr/config", _ -> JSON3.write((; entities=collect(keys(ACTORS)))))
HTTP.register!(ROUTER, "POST", "/actors/{actor_type_name}/{actor_id}/method/", act)
HTTP.register!(ROUTER, "POST", "/actors/{actor_type_name}/{actor_id}/method/fetch", fetch)
HTTP.register!(ROUTER, "DELETE", "/actors/{actor_type_name}/{actor_id}", deactivate)

# """
# Add (or update) the key in `factory` with `app` as prefix.
# """
# function update_scope!(factory::AppSpecification, app::String)
#     new_factory = empty(factory)
#     for (k, v) in factory
#         actor_type = split(k, '.')[end]
#         new_factory["$app.$actor_type"] = v
#     end
#     empty!(factory)
#     merge!(factory, new_factory)
# end

# FIXME: set host to default in k8s
function serve(dir::String)
    #config = load_config(dir)
    #update_scope!(ACTOR_FACTORY, config.app)
    
    # dump the method table to the disk
    open(joinpath(dir, "method_table.json"), "w") do f
        write(f, JugsawIR.json4(typeof((Jugsaw.ACTOR_FACTORY.method_demos...,))))
    end
    open(joinpath(dir, "demos.json"), "w") do f
        write(f, JugsawIR.json4(Jugsaw.ACTOR_FACTORY.method_demos))
    end
    HTTP.serve(ROUTER, host="0.0.0.0")
end
