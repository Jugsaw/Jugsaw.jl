abstract type AbstractHandler end
struct RemoteHandler <: AbstractHandler
    uri::URI
end
RemoteHandler(uri::String="http://localhost:8081/actors/") = RemoteHandler(URI(uri))

struct LocalHandler <: AbstractHandler
    uri::URI
end
LocalHandler(uri::String) = LocalHandler(URI(uri))

# NOTE: demo_result is not the return value!
struct LazyReturn
    uri::URI
    object_id::String
    demo_result
end
function (r::LazyReturn)()
    fet = JSON3.write((; r.object_id))
    return parse4(HTTP.post(r.uri, ["Content-Type" => "application/json"], fet), demo_result)
end

#Base.getproperty(a::App, name::Symbol) = ActorTypeRef(a, string(name))
function request_app(remote::AbstractHandler, appname::Symbol)
    if remote isa LocalHandler
        path = string(remote.uri)
        retstr = read(joinpath(path, "demos.json"), String)
    else
        demo_url = joinpath(remote.uri, "apps", "$appname", "demos")
        r = HTTP.post(demo_url, ["content-type" => "application/json"], req) # Deserialize
        retstr = String(r.body)
    end
    return load_app(retstr)
end
function load_demos_from_dir(dirname::String)
    request_app(LocalHandler(dirname), :any)
end

function call(remote::AbstractHandler, appname::Symbol, demo::Demo, actor_id::String, args...; kwargs...)
    fname = decode_fname(demo.fcall.fname)
    req, types = json4(JugsawFunctionCall(demo.fcall.fname, args, (; kwargs...))) # Serialize
    if remote isa LocalHandler
        path = string(remote.uri)
        mkpath(path)
        open(joinpath(path, "fcall.json"), "w") do f
            write(f, req)
        end
        return () -> parse4(read(joinpath(path, "result.json"), String), demo.result)
    else
        act_url = joinpath(remote.uri, "$appname.$fname", actor_id, "method")
        fetch_url = joinpath(act_url, "fetch")
        r = HTTP.post(act_url, ["content-type" => "application/json"], req) # Deserialize
        res = HTTP.post(fetch_url, ["content-type" => "application/json"], r.body)
        retstr = String(res.body)
        uri = URI(joinpath(string(remote.uri), "actors", "$appname.$fname", actor_id, "method", "fetch"))
        object_id = JSON3.read(retstr).object_id
        return LazyReturn(uri, object_id, demo.result)
    end
end

macro call(remote, ex::Expr)
    @match ex begin
        :($app.$fname($(args...); $(kwargs...))) => begin
            esc(:($call($remote, $app[:name], $match_demo($app, $(QuoteNode(fname)), $args, $kwargs), "0", $(args...); $(kwargs...))))
        end
        _ => :($error("grammar error, should be `@call remote app.fname(args...; kwargs...)` got function call: $($(QuoteNode(ex)))"))
    end
end
# TODO: dispatch to the correct type!
function match_demo(app::App, fname::Symbol, args, kwargs)
    getproperty(app, fname)
end

# can we access the object without knowing the appname and function name?
function fetch(remote::RemoteHandler, object_id::String, appname::Symbol, fname::Symbol, actor_id::String)
    fet = JSON3.write((; object_id))
    return parse4(HTTP.post(joinpath(string(remote.uri), "actors", "$appname.$fname", actor_id, "method", "fetch"), ["Content-Type" => "application/json"], fet), demo.result)
end

healthz(remote::RemoteHandler) = JSON3.read(HTTP.get(joinpath(string(remote.uri), "healthz"))).status
dapr_config(remote::RemoteHandler) = JSON3.read(r(HTTP.get(joinpath(string(remote.uri), "dapr", "config")))).entities
delete(remote::RemoteHandler, appname::Symbol, fname::Symbol, actor_id="0") = HTTP.delete(joinpath(string(remote.uri), "actors", "$appname.$fname", actor_id))