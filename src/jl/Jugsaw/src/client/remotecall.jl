# NOTE: demo_result is not the return value!
struct LazyReturn
    endpoint::String
    job_id::String
    demo_result
end
function (r::LazyReturn)()
    return fetch(r.endpoint, r.job_id, r.demo_result)
end

function request_app(appname::Symbol; endpoint::String="http://localhost:8081/")
    r = new_request(ClientContext(; appname, endpoint), Val(:demos))
    retstr = String(r.body)
    return load_app(retstr, remote.endpoint)
end

function test_demo(endpoint::String, app::App, fname::Symbol)
    for (i, demo) in enumerate(getproperty(app, fname))
        got = call(endpoint, app, fname, i, demo.fcall.args...; demo.fcall.kwargs...)()
        got == demo.result || got ≈ demo.result || return false
    end
    return true
end
call(demo::DemoRef, args...; kwargs...) = call(demo.context, demo.demo, args...; kwargs...)
function call(context::ClientContext, demo::Demo, args...; kwargs...)
    args_adt = adt_norecur(demo.meta["args_type"], args)
    kwargs_adt = adt_norecur(demo.meta["kwargs_type"], (; kwargs...))
    @assert length(args_adt.fields) == length(demo.fcall.args)
    @assert length(kwargs_adt.fields) == length(demo.fcall.kwargs)
    fcall = JugsawADT.Object("JugsawIR.Call",
            [demo.fcall.fname, args_adt, kwargs_adt])
    job_id = String(uuid4())
    safe_request(()->new_request(context, Val(:job), job_id, fcall; endpoint=endpoint, maxtime=60.0, created_by="jugsaw"))
    return LazyReturn(endpoint, job_id, demo.result)
end
function safe_request(f)
    local res
    try
        res = f()
    catch e
        if e isa HTTP.Exceptions.StatusError && e.status == 400
            res = JSON3.read(String(e.response.body))
            Base.println(stdout, res.error)
        end
        Base.rethrow(e)
    end
    return res
end

function adt_norecur(typename::String, x::T) where T
    fields = Any[isdefined(x, fn) ? getfield(x, fn) : undef for fn in fieldnames(T)]
    return JugsawADT.Object(typename, fields)
end

# can we access the object without knowing the appname and function name?
function fetch(endpoint::String, job_id::String, demo_result)
    ret = safe_request(()->new_fetch_request(job_id; endpoint=endpoint))
    return ir2julia(String(ret.body), demo_result)
end

healthz(remote::ClientContext) = JSON3.read(HTTP.get(joinpath(remote.endpoint, "healthz")).body)

function _new_request(context::ClientContext, ::Val{:job}, job_id::String, fcall::JugsawIR.Call; maxtime=10.0, created_by="jugsaw")
    # create a job
    jobspec = (string(job_id), round(Int, time()), created_by, maxtime, fcall.fname, fcall.args, fcall.kwargs)
    ir, = JugsawIR.julia2ir(jobspec)
    # NOTE: UGLY!
    # create a cloud event
    header = ["Content-Type" => "application/json",
        "ce-id"=>"$(uuid4())", "ce-type"=>"any", "ce-source"=>"any",
        "ce-specversion"=>"1.0"
        ]
    data = JSON3.write(ir)
    return ("POST", joinpath(context.endpoint,
        context.endpoint ? "/events/jobs/" : "/v1/proj/$project/app/$appname/ver/$version/func/$fname"
    ), header, data)
end
function _new_request(context::ClientContext, ::Val{:healthz})
    return ("GET", joinpath(context.endpoint, 
        context.endpoint ? "/healthz" : "/v1/proj/$project/app/$appname/ver/$version/healthz"
    ))
end
function _new_request(context::ClientContext, ::Val{:subscribe})
    return ("GET", joinpath(context.endpoint, "/dapr/subscribe"))
end
function _new_request(context::ClientContext, ::Val{:demos})
    return ("GET", joinpath(context.endpoint,
        context.endpoint ? "/demos" : "/v1/proj/$project/app/$appname/ver/$version/func"
    ))
end
function _new_request(context::ClientContext, ::Val{:fetch}, job_id::String)
    return ("GET", joinpath(context.endpoint,
        context.endpoint ? "/events/jobs/fetch" : "/v1/job/$job_id/result"
    ), ["Content-Type" => "application/json"], JSON3.write((; job_id=job_id)))
end
function _new_request(context::ClientContext, ::Val{:api}, fcall::JugsawIR.Call, lang::String)
    return _new_request(Val(:api), JugsawIR.julia2adt(fcall)[1], lang; context.endpoint)
end
function _new_request(context::ClientContext, ::Val{:api}, fcall::JugsawADT, lang::String)
    ir = JugsawIR.adt2ir(JugsawADT.Object("Core.Tuple{Core.String, JugsawIR.Call}", [context.endpoint, fcall]))
    return ("GET", joinpath(context.endpoint,
        context.endpoint ? "/api/$lang" : "/v1/proj/$project/app/$appname/ver/$version/func/$fname/api/$lang"
    ), ["Content-Type" => "application/json"], ir)
end
new_request(context, args...; kwargs...) = HTTP.request(_new_request(context, args...; kwargs...)...)
new_request_obj(context, args...; kwargs...) = HTTP.Request(_new_request(context, args...; kwargs...)...)
