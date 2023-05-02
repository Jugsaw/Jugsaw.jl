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
            do!(state_store, actor.fcall, msg)
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

# do the computation
function do!(state_store::StateStore, democall::JugsawFunctionCall, msg::Message)
    res = fevalself(JugsawFunctionCall(democall.fname, msg.request.args, msg.request.kwargs))
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
    params = HTTP.getparams(http)
    # NOTE: actor_id is harmful to nested call!
    actor_id = string(params["actor_id"])
    tree = JugsawIR.Lerche.parse(JugsawIR.jp, String(http.body))
    # top level function call
    # add a job to the queue
    func_sig = JugsawIR._gettype(tree)
    # handle function request error
    if !haskey(r.app.method_demos, func_sig)
        return _error_nodemo(func_sig)
    end

    # add jobs recursively to the queue
    thisdemo = r.app.method_demos[func_sig].fcall
    try
        resp = addjob!(r, tree, thisdemo, r.app.method_demos, actor_id, 0)
        return HTTP.Response(200, ["Content-Type" => "application/json"], JSON3.write(resp))
    catch e
        if e isa NoDemoException
            return _error_nodemo(e.func_sig)
        end
        Base.rethrow(e)
    end
end
_error_nodemo(func_sig::String) = HTTP.Response(400, ["Content-Type" => "application/json"], JSON3.write((; error="method does not exist, got: $func_sig")))
struct NoDemoException <: Exception
    func_sig::String
end

function addjob!(r::AppRuntime, tree::Tree, thisdemo, demos::Dict{String}, actor_id, level)
    func_sig = _match_jugsawfunctioncall(tree)
    # IF tree is a normal object, return the value directly.
    if func_sig === nothing
        return JugsawIR.fromtree(tree, thisdemo)
    elseif !haskey(demos, func_sig)
        throw(NoDemoException(func_sig))
    end

    nextdemo = demos[func_sig].fcall
    fname, _args, _kwargs = JugsawIR._getfields(tree)
    args = JugsawIR._getfields(_args)
    kwargs = typeof(nextdemo.kwargs)(JugsawIR._getfields(_kwargs))
    # IF tree is a function call, return an `object_id` for return value.
    #     recurse over args and kwargs to get `JugsawFunctionCall` parsed.
    req = JugsawFunctionCall(nextdemo.fname,
        ntuple(i->addjob!(r, args[i], nextdemo.args[i], demos, actor_id, level+1), length(args)),
        typeof(kwargs)(ntuple(i->addjob!(r, kwargs[i], nextdemo.kwargs[i], demos, actor_id, level+1), length(kwargs)))
    )
    if !haskey(demos, func_sig)
        error("function not available: $(func_sig), the list of functions are $(collect(keys(demos)))")
    end

    # add task to the queue
    @info "task added to the queue: $req"
    resp = ObjectRef()
    r.state_store[resp.object_id] = Future()
    # TODO: load actor state from state store
    a = activate(r, func_sig, actor_id)
    put_message(a, Message(req, resp))

    if level == 0
        # IF this is the top level call, return a `ObjectRef` instance.
        return resp
    else
        # OTHERWISE, return an object getter, which is a `JugsawFunctionCall` instance that fetch jobs from the state_store.
        return object_getter(r.state_store, resp.object_id)
    end
end

# returns the function signature
function _match_jugsawfunctioncall(tree::Tree)
    @assert tree.data == "object"
    tree.children[1].children[1] isa JugsawIR.Lerche.Token && return nothing
    func_sig = JugsawIR._gettype(tree)
    ex = Meta.parse(func_sig)
    return @match ex begin
        :(JugsawIR.JugsawFunctionCall{$(_...)}) => func_sig
        _ => nothing
    end
end

# an object getter to load return values of a function call from the state store
function object_getter(state_store::StateStore, object_id::String)
    JugsawFunctionCall(Base.getindex, (state_store, object_id), (;))
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
    HTTP.register!(r, "DELETE", "/actors/{actor_type_name}/{actor_id}", req -> JSON3.write(deactivate!(runtime, req)))
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