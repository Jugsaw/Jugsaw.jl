abstract type AbstractHandler end
struct RemoteHandler <: AbstractHandler
    uri::URI
end
RemoteHandler(uri::String="http://localhost:8081/actors/") = RemoteHandler(URI(uri))

struct LocalHandler <: AbstractHandler
    uri::URI
    handle
end
LocalHandler(uri::String, handler) = LocalHandler(URI(uri), handler)

#Base.getproperty(a::App, name::Symbol) = ActorTypeRef(a, string(name))
function request_app(remote::AbstractHandler, appname::Symbol)
    if remote isa LocalHandler
        path = string(remote.uri)
        retstr = read(joinpath(path, "demos.json"), String)
    else
        demo_url = joinpath(remote.uri, "$appname", "demos")
        r = HTTP.post(demo_url, ["content-type" => "application/json"], req) # Deserialize
        retstr = String(r.body)
    end
    tdemos, ttypes = JugsawIR.Lerche.parse(JugsawIR.jp, retstr).children[].children
    #print_tree(tree)
    types = JugsawIR.fromtree(ttypes, JugsawIR.demoof(TypeTable))
    return load_app(tdemos, types)
end
function load_demos_from_dir(dirname::String)
    request_app(LocalHandler(dirname, nothing), :any)
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
        remote.handle()
        retstr = read(joinpath(path, "result.json"), String)
    else
        act_url = joinpath(remote.uri, "$appname.$fname", actor_id, "method")
        fetch_url = joinpath(act_url, "fetch")
        r = HTTP.post(act_url, ["content-type" => "application/json"], req) # Deserialize
        res = HTTP.post(fetch_url, ["content-type" => "application/json"], r.body)
        retstr = String(res.body)
    end
    return parse4(retstr, demo.result)
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