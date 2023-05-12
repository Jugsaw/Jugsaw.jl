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
    return ir2julia(res, r.demo_result)
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

function test_demo(remote::AbstractHandler, app::App, fname::Symbol)
    for (i, demo) in enumerate(getproperty(app, fname))
        got = call(remote, app, fname, i, demo.fcall.args...; demo.fcall.kwargs...)()
        got == demo.result || got ≈ demo.result || return false
    end
    return true
end
function call(remote::AbstractHandler, app::App, fname::Symbol, which::Int, args...; kwargs...)
    demo = getproperty(app, fname)[which]
    req = JugsawIR.adt2ir(JugsawADT.Object("JugsawIR.Call",
            [demo.fcall.fname,
            adt_norecur(args),
            adt_norecur((; kwargs...))]))
    if remote isa LocalHandler
        path = string(remote.uri)
        mkpath(path)
        open(joinpath(path, "fcall.json"), "w") do f
            write(f, req)
        end
        return () -> ir2julia(read(joinpath(path, "result.json"), String), demo.result)
    else
        act_url = joinpath(remote.uri, "actors", "$(app[:name]).$fname", "method")
        local res
        try
            res = HTTP.post(act_url, ["content-type" => "application/json"], req) # Deserialize
        catch e
            if e isa HTTP.Exceptions.StatusError && e.status == 400
                res = JSON3.read(String(e.response.body))
                Base.println(stdout, res.error)
            end
            Base.rethrow(e)
        end
        retstr = String(res.body)
        uri = URI(joinpath(string(remote.uri), "actors", "$(app[:name]).$fname", "method", "fetch"))
        object_id = JSON3.read(retstr).object_id
        return LazyReturn(uri, object_id, demo.result)
    end
end
function adt_norecur(x::T) where T
    return JugsawADT.Object(type2str(T), 
        Any[isdefined(x, fn) ? getfield(x, fn) : undef for fn in fieldnames(T)]
    )
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
            esc(:($call($remote, $app, $(QuoteNode(fname)), $match_demo($app, $(QuoteNode(fname)), $args, $kwargs), $(args...); $(kwargs...))))
        end
        :($app.$fname.$n($(args...); $(kwargs...))) => begin
            @assert length(String(n)) == 1
            esc(:($call($remote, $app, $(QuoteNode(fname)), $(String(n)[1]-'a'+1), $(args...); $(kwargs...))))
        end
        _ => :($error("grammar error, should be `@call remote app.fname(args...; kwargs...)` got function call: $($(QuoteNode(ex)))"))
    end
end
macro test_demo(remote, ex::Expr)
    @match ex begin
        :($app.$fname) => begin
            esc(:($test_demo($remote, $app, $(QuoteNode(fname)))))
        end
        _ => :($error("grammar error, should be `@call remote app.fname(args...; kwargs...)` got function call: $($(QuoteNode(ex)))"))
    end
end

# can we access the object without knowing the appname and function name?
function fetch(remote::RemoteHandler, object_id::String, app::App, fname::Symbol)
    fet = JSON3.write((; object_id))
    return ir2julia(HTTP.post(joinpath(string(remote.uri), "actors", "$(app.name).$fname", "method", "fetch"), ["Content-Type" => "application/json"], fet), demo.result)
end

healthz(remote::RemoteHandler) = JSON3.read(HTTP.get(joinpath(string(remote.uri), "healthz")).body)
dapr_config(remote::RemoteHandler) = JSON3.read(HTTP.get(joinpath(string(remote.uri), "dapr", "config")).body).entities
delete(remote::RemoteHandler, app::App, fname::Symbol) = JSON3.read(HTTP.delete(joinpath(string(remote.uri), "actors", "$(app[:name]).$fname")).body)