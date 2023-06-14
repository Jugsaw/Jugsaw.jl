function job_handler(r::AppRuntime, req::HTTP.Request)
    @info "call!"
    # top level must be a function call
    # add jobs recursively to the queue
    try
        evt = CloudEvents.from_http(req.headers, req.body)
        # CloudEvent
        jobadt = JugsawIR.ir2adt(String(evt.data))
        job_id, created_at, created_by, maxtime, fname, args, kwargs = jobadt.fields
        jobspec = JobSpec(job_id, created_at, created_by, maxtime, fname, args, kwargs)
        @info "get job: $jobspec"
        addjob!(r, jobspec)
        return HTTP.Response(200, JSON_HEADER, JSON3.write((; job_id=job_id)))
    catch e
        showerror(stdout, e, catch_backtrace())
        return _error_response(e)
    end
end

function fetch_handler(r::AppRuntime, req::HTTP.Request)
    # NOTE: JSON3 errors
    s = String(req.body)
    @info "fetching: $s"
    job_id = JSON3.read(s)["job_id"]
    timeout = get_timeout(r.dapr)
    status, ir = load_object_as_ir(r.dapr, job_id; timeout=timeout)
    if status != :ok
        return _error_response(ErrorException("object not ready yet!"))
    elseif status == :timed_out
        return _error_response(TimedOutException(job_id, timeout))
    else
        return HTTP.Response(200, JSON_HEADER, ir)
    end
end

function demos_handler(app::AppSpecification)
    (demos, types) = JugsawIR.julia2ir(app)
    ir = "[$demos, $types]"
    return HTTP.Response(200, JSON_HEADER, ir)
end

function code_handler(req::HTTP.Request, app::AppSpecification)
    # get language
    params = HTTP.getparams(req)
    lang = params["lang"]
    # get request
    adt = JugsawIR.ir2adt(String(req.body))
    endpoint, fcall = adt.fields
    fname, args, kwargs = fcall.fields
    demo = match_demo(fname, args.typename, kwargs.typename, app)
    if demo === nothing
        return _error_response(NoDemoException(fcall, app))
    else
        try
            code = generate_code(lang, endpoint, app.name, fcall, demo.fcall)
            return HTTP.Response(200, JSON_HEADER, JSON3.write((; code=code)))
        catch e
            return _error_response(e)
        end
    end
end

struct RemoteRoute end
struct LocalRoute end

function get_router(::LocalRoute, runtime::AppRuntime)
    r = HTTP.Router()

    HTTP.register!(r, "GET", "/healthz", _ -> JSON3.write((; status="OK")))
    HTTP.register!(r, "POST", "/events/jobs", req->job_handler(runtime, req))
    HTTP.register!(r, "POST", "/events/jobs/fetch", req -> fetch_handler(runtime, req))
    HTTP.register!(r, "GET", "/demos", _ -> demos_handler(runtime.app))
    # TODO: we need context about endpoint here!
    HTTP.register!(r, "GET", "/api/{lang}", req -> code_handler(req, runtime.app))
    # TODO: complete subscribe
    HTTP.register!(r, "GET", "/dapr/subscribe",
        _ -> JSON3.write([(pubsubname="jobs", topic="$(runtime.app.created_by).$(runtime.app.name).$(rumtime.app.ver)", route="/events/jobs")])
    )
    return r
end

function get_router(::RemoteRoute, runtime::AppRuntime)
    r = HTTP.Router()
    js_folder = joinpath(dirname(dirname(pkgdir(@__MODULE__))), "js")
    # job
    HTTP.register!(r, "GET", "/",
        req->HTTP.Response(200,SIMPLE_HEADER,read(joinpath(js_folder, "jugsawir.html")))
    )
    # HTTP.register!(r, "GET", "/jugsawirparser.js",
    #     req->HTTP.Response(200,SIMPLE_HEADER,read(joinpath(js_folder, "jugsawirparser.js")))
    # )
    # job
    HTTP.register!(r, "POST", "/v1/proj/{project}/app/{appname}/ver/{version}/func/{fname}",
        req->job_handler(runtime, req)
    )
    # fetch
    HTTP.register!(r, "POST", "/v1/job/{job_id}/result",
        req -> fetch_handler(runtime, req)
    )
    # demos
    HTTP.register!(r, "GET", "/v1/proj/{project}/app/{appname}/ver/{version}/func",
        req -> demos_handler(runtime.app)
    )
    # api
    HTTP.register!(r, "GET", "/v1/proj/{project}/app/{appname}/ver/{version}/func/{fname}/api/{lang}",
        req -> code_handler(req, runtime.app)
    )
    # healthz
    HTTP.register!(r, "GET", "/v1/proj/{project}/app/{appname}/ver/{version}/healthz",
        req -> JSON3.write((; status="OK"))
    )
    # subscribe
    # HTTP.register!(r, "GET", "/dapr/subscribe",
    #      req-> JSON3.write([(pubsubname="jobs", topic="$(runtime.app.created_by).$(runtime.app.name).$(rumtime.app.ver)", route="/events/jobs")])
    # )
    return r
end

"""
    simpleserve(runtime::AppRuntime; is_async=false, host="0.0.0.0", port=8088, localurl=false)

Serve this application on specified host and port.

### Arguments
* `runtime` is an [`AppRuntime`](@ref) instance.

### Keyword arguments
* `is_async` is a switch to turn on the asynchronous mode for debugging.
* `host` is the IP address or url of the host.
* `port` is the port to serve the application.
* `localurl` is a switch to serve in local mode with a simplified routing table.
In the local mode, the project name and application name are not required in the request url.
"""
function simpleserve(runtime::AppRuntime;
        is_async::Bool=false,
        host::String="0.0.0.0",
        port::Int=8088,
        localurl::Bool=false,
        )
    # release demo
    r = get_router(localurl ? LocalRoute() : RemoteRoute(), runtime)
    if is_async
        @async HTTP.serve(r, host, port)
    else
        HTTP.serve(r, host, port)
    end
end