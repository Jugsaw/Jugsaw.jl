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
function do!(state_store::StateStore, democall::Call, msg::Message)
    try
        res = fevalself(Call(democall.fname, msg.request.args, msg.request.kwargs))
        @info "store result: $res"
        # TODO: custom serializer
        state_store[msg.response.object_id] = res
    catch e
        # if the program errors, returns a cached error object to be thrown.
        state_store[msg.response.object_id] = CachedError(e, _error_msg(e))
    end
end
# a run time instance
struct AppRuntime
    app::AppSpecification
    actors::Dict{String,Any}
    # This is a simple in-memory state store which holds the results from the actor calls.
    # We may add many different kinds of state store later (local file or Database).
    state_store::StateStore
end
function AppRuntime(app::AppSpecification)
    return AppRuntime(app, Dict{String,Any}(), StateStore(Dict{String,Future}()))
end

function Base.empty!(r::AppRuntime)
    empty!(r.actors)
    empty!(r.state_store)
end

#####

"""
Try to activate an actor. If the requested actor does not exist yet, a new
one is created based on the registered `ActorFactor` of `actor_type`. Note that
the actor may be configured to recover from its lastest state snapshot.
"""
function activate(r::AppRuntime, actor_type::JugsawADT)
    demo = match_demo_or_throw(actor_type, r.app)
    get!(r.actors, actor_type.fields[1]) do
        Actor(r.state_store, demo)
    end
end

function act!(r::AppRuntime, http::HTTP.Request)
    # params = HTTP.getparams(http)   # we can obtain request params like this
    adt = JugsawIR.ir2adt(String(http.body))
    @info "got adt: $adt"
    # top level must be a function call
    # add jobs recursively to the queue
    try
        thisdemo = match_demo_or_throw(adt, r.app).fcall
        resp = addjob!(r, adt, thisdemo)
        return HTTP.Response(200, ["Content-Type" => "application/json"], JSON3.write(resp))
    catch e
        @info e
        return _error_response(e)
    end
end

function match_demo_or_throw(adt::JugsawADT, app::AppSpecification)
    if adt.typename != "JugsawIR.Call"
        throw(BadSyntax(adt))
    end
    fname, args, kwargs = adt.fields
    res = _match_demo(fname, args.typename, kwargs.typename, app)
    if res === nothing
        throw(NoDemoException(adt, app))
    end
    return res
end
function _match_demo(fname, args_type, kwargs_type, app::AppSpecification)
    if !haskey(app.method_demos, fname) || isempty(app.method_demos[fname])
        return nothing
    end
    for demo in app.method_demos[fname]
        _, dargs, dkwargs = demo.fcall.fname, demo.meta["args_type"], demo.meta["kwargs_type"]
        if dargs == args_type && dkwargs == kwargs_type
            return demo
        end
    end
    return nothing
end

function addjob!(r::AppRuntime, adt::JugsawADT, thisdemo::Call)
    # find a demo
    fname, args, kwargs = adt.fields
    # IF tree is a function call, return an `object_id` for return value.
    #     recurse over args and kwargs to get `Call` parsed.
    req = Call(thisdemo.fname,
        ntuple(i->renderobj!(r, args.fields[i], thisdemo.args[i]), length(args.fields)),
        typeof(thisdemo.kwargs)(ntuple(i->renderobj!(r, kwargs.fields[i], thisdemo.kwargs[i]), length(kwargs.fields)))
    )
    # add task to the queue
    @info "task added to the queue: $req"
    resp = ObjectRef()
    r.state_store[resp.object_id] = Future()
    # TODO: load actor state from state store
    a = activate(r, adt)
    put_message(a, Message(req, resp))

    # Return a `ObjectRef` instance.
    return resp
end

# if adt is a function call, launch a job and return an object getter, else, return an object.
function renderobj!(r::AppRuntime, adt, thisdemo)
    if adt isa JugsawADT && hasproperty(adt, :typename) && adt.typename == "JugsawIR.Call"
        fdemo = match_demo_or_throw(adt, r.app)
        resp = addjob!(r, adt, fdemo.fcall)
        # Return an object getter, which is a `Call` instance that fetches objects from the state_store.
        return object_getter(r.state_store, resp.object_id)
    else
        return JugsawIR.adt2julia(adt, thisdemo)
    end
end

# an object getter to load return values of a function call from the state store
function object_getter(state_store::StateStore, object_id::String)
    function getter(s::StateStore, id::String)
        res = s[id]
        # rethrow a cached error
        res isa CachedError && Base.rethrow(res.exception)
        return res
    end
    Call(getter, (state_store, object_id), (;))
end

"""
Remove idle actors. Actors may be configure to persistent its current state.
"""
function deactivate!(r::AppRuntime, req::HTTP.Request)
    ps = HTTP.getparams(req)
    atype = string(ps["actor_type_name"])
    @show atype, r.actors
    actor = get(r.actors, atype, nothing)
    if !isnothing(actor)
        close(actor)
        delete!(r.actors, atype)
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
    res = r.state_store[ref.object_id]
    if res isa CachedError
        return _error_response(res.exception)
    end
    return julia2ir(res)[1]
end

#####
# Service
#####

# save demos to the disk
function save_demos(dir::String, methods::AppSpecification)
    mkpath(dir)
    demos, types = JugsawIR.julia2ir(methods)
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
    adt = JugsawIR.ir2adt(sdemos)
    appadt, typesadt = adt.storage
    return JugsawIR.adt2julia(appadt, demos), JugsawIR.adt2julia(typesadt, JugsawIR.demoof(JugsawIR.TypeTable))
end

# FIXME: set host to default in k8s
function get_router(runtime::AppRuntime)
    # start the service
    r = HTTP.Router()
    HTTP.register!(r, "GET", "/healthz", _ -> JSON3.write((; status="OK")))
    HTTP.register!(r, "GET", "/dapr/config", _ -> JSON3.write((; entities=collect(keys(runtime.actors)))))
    HTTP.register!(r, "GET", "/apps/{appname}/demos", _ -> ((demos, types) = JugsawIR.julia2ir(runtime.app); "[$demos, $types]"))
    HTTP.register!(r, "POST", "/actors/{actor_type_name}/method/", req -> act!(runtime, req))
    HTTP.register!(r, "POST", "/actors/{actor_type_name}/method/fetch", req -> fetch(runtime, req))
    HTTP.register!(r, "DELETE", "/actors/{actor_type_name}", req -> JSON3.write(deactivate!(runtime, req)))
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