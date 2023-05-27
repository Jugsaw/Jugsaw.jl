abstract type AbstractHandler end
struct RemoteHandler <: AbstractHandler
    uri::URI
end
RemoteHandler(uri::String="http://localhost:8081/") = RemoteHandler(URI(uri))

struct LocalHandler <: AbstractHandler
    uri::URI
end
LocalHandler(uri::String) = LocalHandler(URI(; scheme="file", host=uri))

# NOTE: demo_result is not the return value!
struct LazyReturn
    uri::URI
    object_id::String
    demo_result
end
function (r::LazyReturn)()
    return fetch(r.uri, r.object_id, r.demo_result)
end

function request_app(appname::Symbol; uri::String="http://localhost:8081/")
    _uri = URI(uri)
    if _uri.scheme == "https" || _uri.scheme == "http"
        return request_app(RemoteHandler(_uri), appname)
    elseif _uri.scheme == "file"
        return request_app(LocalHandler(_uri), appname)
    else
        error("uri string scheme error, expected http, https or file, got: $(_uri.scheme)")
    end
end
function request_app(remote::AbstractHandler, appname::Symbol)
    if remote isa LocalHandler
        path = remote.uri.host * remote.uri.path
        retstr = read(joinpath(path, "demos.json"), String)
    else
        demo_url = joinpath(remote.uri, "apps", "$appname", "demos")
        r = HTTP.get(demo_url) # Deserialize
        retstr = String(r.body)
    end
    return load_app(retstr, remote.uri)
end
function load_demos_from_dir(dirname::String)
    request_app(LocalHandler(dirname), :any)
end

function test_demo(uri::URI, app::App, fname::Symbol)
    for (i, demo) in enumerate(getproperty(app, fname))
        got = call(uri, app, fname, i, demo.fcall.args...; demo.fcall.kwargs...)()
        got == demo.result || got ≈ demo.result || return false
    end
    return true
end
call(demo::DemoRef, args...; kwargs...) = call(demo.uri, demo.demo, args...; kwargs...)
function call(uri::URI, demo::Demo, args...; kwargs...)
    args_adt = adt_norecur(demo.meta["args_type"], args)
    kwargs_adt = adt_norecur(demo.meta["kwargs_type"], (; kwargs...))
    @assert length(args_adt.fields) == length(demo.fcall.args)
    @assert length(kwargs_adt.fields) == length(demo.fcall.kwargs)
    req = JugsawIR.adt2ir(JugsawADT.Object("JugsawIR.Call",
            [demo.fcall.fname, args_adt, kwargs_adt]))
    if uri.scheme == "file"
        path = uri.host * uri.path
        mkpath(path)
        open(joinpath(path, "fcall.json"), "w") do f
            write(f, req)
        end
        return () -> ir2julia(read(joinpath(path, "result.json"), String), demo.result)
    else
        act_url = joinpath(uri, "method")
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
        object_id = JSON3.read(retstr).object_id
        return LazyReturn(uri, object_id, demo.result)
    end
end
function adt_norecur(typename::String, x::T) where T
    fields = Any[isdefined(x, fn) ? getfield(x, fn) : undef for fn in fieldnames(T)]
    return JugsawADT.Object(typename, fields)
end

# can we access the object without knowing the appname and function name?
function fetch(uri::URI, job_id::String, demo_result)
    ret = new_fetch_request(job_id; endpoint=uri)
    return ir2julia(String(ret.body), demo_result)
end

healthz(remote::RemoteHandler) = JSON3.read(HTTP.get(joinpath(remote.uri, "healthz")).body)

function new_job_request(fcall::JugsawIR.Call; maxtime=10.0, created_by="jugsaw", endpoint="")
    # create a job
    job_id = string(uuid4())
    jobspec = (job_id, round(Int, time()), created_by, maxtime, fcall.fname, fcall.args, fcall.kwargs)
    ir, = JugsawIR.julia2ir(jobspec)
    # NOTE: UGLY!
    # create a cloud event
    req = HTTP.Request("POST", joinpath(endpoint, "/events/jobs/"), ["Content-Type" => "application/json",
        "ce-id"=>"$(uuid4())", "ce-type"=>"any", "ce-source"=>"any",
        "ce-specversion"=>"1.0"
        ],
        JSON3.write(ir)
    )
    return req, job_id
end
function new_healthz_request(; endpoint="")
    return HTTP.Request("GET", joinpath(endpoint, "/healthz"))
end
function new_demos_request(; endpoint="")
    return HTTP.Request("GET", joinpath(endpoint, "/demos"))
end
function new_fetch_request(job_id::String; endpoint="")
    return HTTP.Request("GET", joinpath(endpoint, "/events/jobs/fetch"), ["Content-Type" => "application/json"], JSON3.write((; job_id=job_id)))
end
function new_api_request(fcall::JugsawIR.Call, lang::String; endpoint="")
    ir, = julia2ir((; endpoint, fcall))
    return HTTP.Request("POST", joinpath(endpoint, "/api/$lang"), ["Content-Type" => "application/json"], ir; context=Dict(:params=>Dict("lang"=>"$lang")))
end

