export serve, @register

using UUIDs: uuid4
using HTTP
using JSON3
using Distributed: Future

#####

macro register(exs...)
    a = exs[1]
    name = if a isa Symbol
        string(a)
    elseif a isa Expr && a.head == :call
        string(a.args[1])
    else
        nothing
    end

    thunk = esc(:(() -> ($(a))))

    quote
        register(ActorFactory($thunk, $name))
    end
end

#####

struct StateStore
    store::Dict{String,Future}
end

STATE_STORE = StateStore(Dict{String,String}())

Base.setindex!(s::StateStore, v::Future, k) = s.store[k] = v
Base.setindex!(s::StateStore, v, k) = put!(s.store[k], v)
Base.getindex(s::StateStore, k) = s.store[k][]

#####

struct ActorFactory
    factory::Any
    name::String
end

ActorFactory(f, ::Nothing) = ActorFactory(f, nameof(f))

(f::ActorFactory)() = f.factory()

struct Message
    body::Union{Vector{UInt8},IO}
    res::String
end

Message(body) = Message(body, string(uuid4()))

struct Actor{T}
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

function (a::Actor)(msg::Message)
    # FIXME: no need if we have a state store db
    put!(a.mailbox, msg)
end

act(actor::Any, msg) = actor(msg)

function act(actor::Any, msg::Message)
    # TODO: custom deserializer
    payload = JSON3.read(msg.body)
    res = act(actor, payload)
    # TODO: custom serializer
    s_res = JSON3.write(res)
    STATE_STORE[msg.res] = s_res
end

#####

const ACTOR_FACTORY = Dict{String,ActorFactory}()
const ACTORS = Dict{Pair{String,String},Any}()

register(a::ActorFactory) = ACTOR_FACTORY[a.name] = a

function activate(actor_type::String, actor_id::String)
    if haskey(ACTOR_FACTORY, actor_type)
        f = ACTOR_FACTORY[actor_type]
        get!(ACTORS, actor_type => actor_id) do
            Actor(f())
        end
    end
end

function act(req::HTTP.Request)
    ps = HTTP.getparams(req)
    a = activate(string(ps["actor_type_name"]), string(ps["actor_id"]))
    # TODO: load actor state from state store
    msg = Message(req.body)
    STATE_STORE[msg.res] = Future()
    a(msg)
    HTTP.Response(200, msg.res)
end

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

function fetch(req::HTTP.Request)
    id = JSON3.read(req.body)
    STATE_STORE[id]
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


serve() = HTTP.serve(ROUTER)
serve!() = HTTP.serve!(ROUTER)
