#####
struct StateStore
    store::Dict{String,Future}
end

Base.setindex!(s::StateStore, v::Future, k) = s.store[k] = v
Base.setindex!(s::StateStore, v, k) = put!(s.store[k], v)
Base.getindex(s::StateStore, k) = s.store[k][]

#####

"""
Describe current status of an actor.
"""
struct Actor
    # actor is a function demo
    actor::JugsawDemo
    taskref::Ref{Task}
    mailbox::Channel{Message}
end

function Actor(state_store, actor::JugsawDemo)
    taskref = Ref{Task}()
    chnl = Channel{Message}(taskref=taskref) do ch
        for msg in ch
            act!(state_store, actor.fcall, msg)
        end
    end
    Actor(deepcopy(actor), taskref, chnl)
end

Base.close(a::Actor) = close(a.mailbox) # TODO: save actor state to state store

# NOTE: I prefer using a function name, otherwise it is hard to located the function definition.
function put_message(a::Actor, msg::Message)
    # FIXME: no need if we have a state store db
    put!(a.mailbox, msg)
end

function act!(state_store::StateStore, democall::JugsawFunctionCall, msg::Message)
    res = feval(democall, msg.request.args...; msg.request.kwargs...)
    @info "store result: $res"
    # TODO: custom serializer
    s_res, _ = JugsawIR.json4(res)
    state_store[msg.response.object_id] = s_res
end

# a run time instance
struct AppRuntime
    app::AppSpecification
    actors::Dict{Pair{String,String},Any}
    # This is a simple in-memory state store which holds the results from the actor calls.
    # We may add many different kinds of state store later (local file or Database).
    state_store::StateStore
end
function AppRuntime(app::AppSpecification)
    return AppRuntime(app, Dict{Pair{String,String},Any}(), StateStore(Dict{String,Future}()))
end

function Base.empty!(r::AppRuntime)
    empty!(r.actors)
    empty!(r.state_store)
end

#####

"""
Try to activate an actor. If the actor of `actor_id` does not exist yet, a new
one is created based on the registered `ActorFactor` of `actor_type`. Note that
the actor may be configured to recover from its lastest state snapshot.
"""
function activate(r::AppRuntime, actor_type::String, actor_id::String)
    if haskey(r.app.method_demos, actor_type)
        get!(r.actors, actor_type => actor_id) do
            Actor(r.state_store, r.app.method_demos[actor_type])
        end
    else
        error("actor type does not exist: $actor_type, we have $(keys(r.app.method_demos))")
    end
end

function act!(r::AppRuntime, http::HTTP.Request)
    ps = HTTP.getparams(http)
    # find the correct method
    fcall = String(http.body)
    fname, req = parse_fcall(fcall, r.app.method_demos)
    a = activate(r, fname, string(ps["actor_id"]))
    # TODO: load actor state from state store
    #req = JSON3.read(http.body, JugsawFunctionCall)
    @info "got task: $req"
    resp = ObjectRef()
    r.state_store[resp.object_id] = Future()
    put_message(a, Message(req, resp))
    HTTP.Response(200, ["Content-Type" => "application/json"], JSON3.write(resp))
end
function parse_fcall(fcall::String, demos::Dict{String})
    @info fcall
    type_sig, tree = get_typesig(fcall)
    if !haskey(demos, type_sig)
        error("function not available: $(type_sig), the list of functions are $(collect(keys(demos)))")
    end
    demo = demos[type_sig]
    return type_sig, JugsawIR.fromtree(tree, demo.fcall)
end
function get_typesig(fcall)
    tree = JugsawIR.Lerche.parse(JugsawIR.jp, fcall)
    return JugsawIR._gettype(tree), tree
end

"""
Remove idle actors. Actors may be configure to persistent its current state.
"""
function deactivate!(r::AppRuntime, req::HTTP.Request)
    ps = HTTP.getparams(req)
    atype = string(ps["actor_type_name"])
    aid = string(ps["actor_id"])
    actor = get(r.actors, atype => aid, nothing)
    if !isnothing(actor)
        close(actor)
        delete!(r.actors, atype => aid)
        return true
    end
    return false
end

"""
This is just a workaround. In the future, users should fetch results from StateStore directly.
"""
function fetch(r::AppRuntime, req::HTTP.Request)
    # NOTE: JSON3 errors
    s = String(req.body)
    @info "fetching: $s"
    ref = ObjectRef(JSON3.read(s)["object_id"])
    return r.state_store[ref.object_id]
end

#####
# Service
#####

# save demos to the disk
function save_demos(dir::String, methods::AppSpecification)
    mkpath(dir)
    demos, types = JugsawIR.json4(methods)
    fdemos = joinpath(dir, "demos.json")
    @info "dumping demos to: $fdemos"
    open(fdemos, "w") do f
        write(f, "[$demos, $types]")
    end
end

# load demos from the disk
function load_demos_from_dir(dir::String, demos)
    sdemos = read(joinpath(dir, "demos.json"), String)
    return load_demos(sdemos, demos)
end
function load_demos(sdemos::String, demos)
    ds, ts = JugsawIR.Lerche.parse(JugsawIR.jp, sdemos).children[].children
    newdemos = JugsawIR.fromtree(ds, demos)
    newtypes = JugsawIR.fromtree(ts, JugsawIR.demoof(JugsawIR.TypeTable))
    return newdemos, newtypes
end

# FIXME: set host to default in k8s
function get_router(runtime::AppRuntime)
    # start the service
    r = HTTP.Router()
    HTTP.register!(r, "GET", "/healthz", _ -> JSON3.write((; status="OK")))
    HTTP.register!(r, "GET", "/dapr/config", _ -> JSON3.write((; entities=collect(keys(runtime.actors)))))
    HTTP.register!(r, "GET", "/apps/{appname}/demos", _ -> ((demos, types) = JugsawIR.json4(runtime.app); "[$demos, $types]"))
    HTTP.register!(r, "POST", "/actors/{actor_type_name}/{actor_id}/method/", req -> act!(runtime, req))
    HTTP.register!(r, "POST", "/actors/{actor_type_name}/{actor_id}/method/fetch", req -> fetch(runtime, req))
    HTTP.register!(r, "DELETE", "/actors/{actor_type_name}/{actor_id}", req -> deactivate!(runtime, req))
    return r
end

function serve(runtime::AppRuntime, dir=nothing; is_async=isdefined(Main, :InteractiveUtils))
    dir === nothing || save_demos(dir, runtime.app)
    r = get_router(runtime)
    if is_async
        #HTTP.serve!(r, "0.0.0.0", 8081)
        @async HTTP.serve(r, "0.0.0.0", 8081)
    else
        HTTP.serve(r, "0.0.0.0", 8081)
    end
end

function serve(app::AppSpecification, dir=nothing; is_async=isdefined(Main, :InteractiveUtils))
    # create an application runtime, which will be used to store cached data and actors
    r = Jugsaw.AppRuntime(app)
    serve(r, dir; is_async)
end