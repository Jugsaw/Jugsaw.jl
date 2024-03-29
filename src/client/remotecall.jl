# NOTE: demo_result is not the return value!
"""
$(TYPEDEF)

A callable lazy result. To fetch the result value, please use `lazyresult()`.

### Fields
$(TYPEDFIELDS)
"""
struct LazyReturn
    context::ClientContext
    job_id::String
    demo_result
end
function (r::LazyReturn)()
    return fetch(r.context, r.job_id, r.demo_result)
end

"""
$(TYPEDSIGNATURES)

Request an application from an endpoint.

###  Arguments
* `context` is a [`ClientContext`](@ref) instance, which contains contextual information like the endpoint.
* `appname` specificies the application to be fetched.
"""
function request_app(context::ClientContext, appname::Symbol)
    context = copy(context)
    context.appname = appname
    r = new_request(context, Val(:demos))
    retstr = String(r.body)
    return load_app(context, retstr)
end

function test_demo(endpoint::String, app::App, fname::Symbol)
    for (i, demo) in enumerate(getproperty(app, fname))
        got = call(ClientContext(; endpoint), app, fname, i, demo.fcall.args...; demo.fcall.kwargs...)()
        got == demo.result || got ≈ demo.result || return false
    end
    return true
end

"""
$TYPEDSIGNATURES

Launch a function call.
"""
function call(context::ClientContext, demo::Demo, args...; kwargs...)
    @assert length(args) == length(demo.fcall.args)
    # fetch kwargs, if not set, use demo
    kws = fieldnames(typeof(demo.fcall.kwargs))
    kwargs = Dict([k=>(isdefined(kwargs, fn) ? JugsawIR.julia2adt(getfield(x, fn))[1] : getfield(demo.fcall.kwargs, fn)) for (k, fn) in enumerate(kws)])
    fcall = Call(demo.fcall.fname, args, (; kwargs...))
    job_id = string(uuid4())
    safe_request(()->new_request(context, Val(:job), job_id, fcall; maxtime=60.0, created_by="jugsaw"))
    return LazyReturn(context, job_id, demo.result)
end

function get_kws_from_type(kwargs_type::String)
    s = match(r"Core.NamedTuple{\((.*)\), Core.Tuple{.*}}", kwargs_type)[1]
    isempty(s) && return String[]
    return strip.(split(s, ","), Ref([' ', ':']))
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

"""
$TYPEDSIGNATURES

Fetch results from the endpoint with job id.
"""
# can we access the object without knowing the appname and function name?
function fetch(context::ClientContext, job_id::String, demo_result)
    ret = safe_request(()->new_request(context, Val(:fetch), job_id))
    return JugsawIR.read_object(ret.body, demo_result)
end

"""
$TYPEDSIGNATURES

Check the status of the application.
"""
function healthz(context::ClientContext)
    path = context.localurl ? "healthz" : "v1/proj/$(context.project)/app/$(context.appname)/ver/$(context.version)/healthz"
    JSON3.read(HTTP.get(joinpath(context.endpoint, path)).body)
end


function _new_request(context::ClientContext, ::Val{:job}, job_id::String, fcall; maxtime=10.0, created_by="jugsaw")
    # create a job
    jobspec = (; id=job_id, created_at=time(), created_by, maxtime, fcall)
    ir = JugsawIR.write_object(jobspec)
    # NOTE: UGLY!
    # create a cloud event
    header = ["Content-Type" => "application/json",
        "ce-id"=>"$(uuid4())", "ce-type"=>"any", "ce-source"=>"julia",
        "ce-specversion"=>"1.0"
        ]
    return ("POST", joinpath(context.endpoint,
        context.localurl ? "events/jobs/" : "v1/proj/$(context.project)/app/$(context.appname)/ver/$(context.version)/func/$(fcall.fname)"
    ), header, ir)
end
function _new_request(context::ClientContext, ::Val{:healthz})
    return ("GET", joinpath(context.endpoint, 
        context.localurl ? "healthz" : "v1/proj/$(context.project)/app/$(context.appname)/ver/$(context.version)/healthz"
    ))
end
function _new_request(context::ClientContext, ::Val{:demos})
    @info context
    return ("GET", joinpath(context.endpoint,
        context.localurl ? "demos" : "v1/proj/$(context.project)/app/$(context.appname)/ver/$(context.version)/func"
    ))
end
function _new_request(context::ClientContext, ::Val{:fetch}, job_id::String)
    return ("POST", joinpath(context.endpoint,
        context.localurl ? "events/jobs/fetch" : "v1/job/$job_id/result"
    ), ["Content-Type" => "application/json"], JSON3.write((; job_id=job_id)))
end
new_request(context, args...; kwargs...) = HTTP.request(_new_request(context, args...; kwargs...)...)
new_request_obj(context, args...; kwargs...) = HTTP.Request(_new_request(context, args...; kwargs...)...)
