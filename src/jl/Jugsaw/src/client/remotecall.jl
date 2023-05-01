abstract type AbstractHandler end
struct RemoteHandler <: AbstractHandler
    uri::URI
end
RemoteHandler(uri::String="http://localhost:8081/") = RemoteHandler(URI(uri))

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
    res = String(HTTP.post(r.uri, ["Content-Type" => "application/json"], fet).body)
    println(res)
    println(r.demo_result)
    return parse4(res, r.demo_result)
end

#Base.getproperty(a::App, name::Symbol) = ActorTypeRef(a, string(name))
function request_app(remote::AbstractHandler, appname::Symbol)
    if remote isa LocalHandler
        path = string(remote.uri)
        retstr = read(joinpath(path, "demos.json"), String)
    else
        demo_url = joinpath(remote.uri, "apps", "$appname", "demos")
        r = HTTP.get(demo_url) # Deserialize
        retstr = String(r.body)
    end
    return load_app(retstr)
end
function load_demos_from_dir(dirname::String)
    request_app(LocalHandler(dirname), :any)
end

function test_demo(remote::AbstractHandler, app::App, fname::Symbol, actor_id::String)
    for (i, (sig, demo)) in enumerate(getproperty(app, fname))
        got = call(remote, app, fname, i, actor_id, demo.fcall.args...; demo.fcall.kwargs...)()
        got == demo.result || got ≈ demo.result || return false
    end
    return true
end
function call(remote::AbstractHandler, app::App, fname::Symbol, which::Int, actor_id::String, args...; kwargs...)
    fsig, demo = getproperty(app, fname)[which]
    req = render_jsoncall(fsig, demo.fcall.fname, args, (; kwargs...)) # Serialize
    if remote isa LocalHandler
        path = string(remote.uri)
        mkpath(path)
        open(joinpath(path, "fcall.json"), "w") do f
            write(f, req)
        end
        return () -> parse4(read(joinpath(path, "result.json"), String), demo.result)
    else
        act_url = joinpath(remote.uri, "actors", "$(app[:name]).$fname", actor_id, "method")
        #fetch_url = joinpath(act_url, "fetch")
        res = HTTP.post(act_url, ["content-type" => "application/json"], req) # Deserialize
        #res = HTTP.post(fetch_url, ["content-type" => "application/json"], r.body)
        retstr = String(res.body)
        uri = URI(joinpath(string(remote.uri), "actors", "$(app[:name]).$fname", actor_id, "method", "fetch"))
        object_id = JSON3.read(retstr).object_id
        return LazyReturn(uri, object_id, demo.result)
    end
end

function render_jsoncall(fsig, fname, args, kwargs)
    str, obj = json4(JugsawObj(fsig, [fname, args, kwargs], ["fname", "args", "kwargs"]))
    return str
end
# TODO: dispatch to the correct type!
function match_demo(app::App, fname::Symbol, args, kwargs)
    demos = getproperty(app, fname)
    if length(demos) > 1
        error("matching functions with the same name is not yet defined!")
    else
        return 1
    end
end

macro call(remote, ex::Expr)
    @match ex begin
        :($app.$fname($(args...); $(kwargs...))) => begin
            esc(:($call($remote, $app, $(QuoteNode(fname)), $match_demo($app, $(QuoteNode(fname)), $args, $kwargs), "0", $(args...); $(kwargs...))))
        end
        :($app.$fname.$n($(args...); $(kwargs...))) => begin
            @assert length(String(n)) == 1
            esc(:($call($remote, $app, $(QuoteNode(fname)), $(String(n)[1]-'a'+1), "0", $(args...); $(kwargs...))))
        end
        _ => :($error("grammar error, should be `@call remote app.fname(args...; kwargs...)` got function call: $($(QuoteNode(ex)))"))
    end
end
macro test_demo(remote, ex::Expr)
    @match ex begin
        :($app.$fname) => begin
            esc(:($test_demo($remote, $app, $(QuoteNode(fname)), "0")))
        end
        _ => :($error("grammar error, should be `@call remote app.fname(args...; kwargs...)` got function call: $($(QuoteNode(ex)))"))
    end
end

# can we access the object without knowing the appname and function name?
function fetch(remote::RemoteHandler, object_id::String, app::App, fname::Symbol, actor_id::String)
    fet = JSON3.write((; object_id))
    return parse4(HTTP.post(joinpath(string(remote.uri), "actors", "$(app.name).$fname", actor_id, "method", "fetch"), ["Content-Type" => "application/json"], fet), demo.result)
end

healthz(remote::RemoteHandler) = JSON3.read(HTTP.get(joinpath(string(remote.uri), "healthz")).body)
dapr_config(remote::RemoteHandler) = JSON3.read(HTTP.get(joinpath(string(remote.uri), "dapr", "config")).body).entities
delete(remote::RemoteHandler, app::App, fname::Symbol, actor_id="0") = JSON3.read(HTTP.delete(joinpath(string(remote.uri), "actors", "$(app[:name]).$fname", actor_id)).body)