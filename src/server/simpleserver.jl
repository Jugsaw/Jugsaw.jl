"""
$TYPEDSIGNATURES

Handle the request of function call and returns a response with job id.

### Request
A Jugsaw IR that corresponds to a [`JobSpec`](@ref) instance.

### Response
* [Success]: a JSON object `{"job_id" : ...}`.
* [NoDemoException]: a JSON object `{"error" : ...}`.
"""
function cli_handler(r::AppRuntime, req::HTTP.Request)
    # top level must be a function call
    # add jobs recursively to the queue
    try
        evt = CloudEvents.from_http(req.headers, req.body)
        job_id, created_at, created_by, maxtime, fname, args, kwargs = JSON3.read(evt.data)
        # get demo so that we can parse args and kwargs
        thisdemo = get_demo(app, job_id, fname)
        jargs = JugsawIR.cli2julia(args, thisdemo.fcall.args)
        jkwargs = JugsawIR.cli2julia(args, thisdemo.fcall.kwargs)
        jobspec = Job(job_id, created_at, created_by, maxtime, thisdemo, jargs, jkwargs)
        @info "get job: $jobspec"
        addjob!(r, jobspec)
        return HTTP.Response(200, JSON_HEADER, JSON3.write((; job_id=job_id)))
    catch e
        showerror(stdout, e, catch_backtrace())
        return _error_response(e)
    end
end

"""
$TYPEDSIGNATURES

Handle the request of function call and returns a response with job id.

### Request
A Jugsaw IR that corresponds to a [`JobSpec`](@ref) instance.

### Response
* [Success]: a JSON object `{"job_id" : ...}`.
* [NoDemoException]: a JSON object `{"error" : ...}`.
"""
function job_handler(r::AppRuntime, req::HTTP.Request)
    # top level must be a function call
    # add jobs recursively to the queue
    try
        evt = CloudEvents.from_http(req.headers, req.body)
        # CloudEvent
        jobadt = JugsawIR.ir2adt(String(evt.data))
        job_id, created_at, created_by, maxtime, fname, args, kwargs = JugsawIR.unpack_fields(jobadt)
        jobspec = JobSpec(job_id, created_at, created_by, maxtime, fname, args, kwargs)
        @info "get job: $jobspec"
        addjob!(r, jobspec)
        return HTTP.Response(200, JSON_HEADER, JSON3.write((; job_id=job_id)))
    catch e
        showerror(stdout, e, catch_backtrace())
        return _error_response(e)
    end
end

"""
$TYPEDSIGNATURES

Handle the request of fetching computed results and return a response with job id.

### Request
A JSON payload that specifies the job id as `{"job_id" : ...}`.

### Response
* [Success]: Jugsaw IR in the form of JSON payload.
* [TimedOutException]: a JSON object `{"error" : ...}`.
* [ErrorException]: a JSON object `{"error" : ...}`.
"""
function fetch_handler(r::AppRuntime, req::HTTP.Request)
    # NOTE: JSON3 errors
    s = String(req.body)
    @info "fetching: $s"
    job_id = JSON3.read(s)["job_id"]
    timeout = get_timeout()
    status, ir = load_object_as_ir(r.dapr, job_id; timeout=timeout)
    if status != :ok
        return _error_response(ErrorException("object not ready yet!"))
    elseif status == :timed_out
        return _error_response(TimedOutException(job_id, timeout))
    else
        return HTTP.Response(200, JSON_HEADER, ir)
    end
end

"""
$TYPEDSIGNATURES

Handle the request of getting application specification, including registered function demos and type definitions.

### Response
* [Success]: Jugsaw IR in the form of a JSON object.
"""
function demos_handler(app::AppSpecification)
    (demos, types) = JugsawIR.julia2ir(app)
    ir = "['list', $demos, $types]"
    return HTTP.Response(200, JSON_HEADER, ir)
end

"""
$TYPEDSIGNATURES

Handle the request of generating the API for calling from a specific client language.

### Response
* [Success]: a JSON object with requested API code `{"code" : ...}`.
* [NoDemoException]: a JSON object `{"error" : ...}`.
* [ErrorException]: a JSON object `{"error" : ...}`.
"""
function code_handler(req::HTTP.Request, app::AppSpecification)
    # get language
    params = HTTP.getparams(req)
    lang = params["lang"]
    # get request
    adt = JugsawIR.ir2adt(String(req.body))
    endpoint, fcall = JugsawIR.unpack_fields(adt)
    fname, args, kwargs = JugsawIR.unpack_call(fcall)
    if !haskey(app.method_demos, fname)
        return _error_response(NoDemoException(fcall, app))
    else
        try
            adt, type_table = JugsawIR.julia2adt(app)
            code = generate_code(lang, endpoint, app.name, fname, fcall, type_table)
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
    js_folder = joinpath(pkgdir(@__MODULE__), "js")
    # web page
    HTTP.register!(r, "GET", "/",
        req->HTTP.Response(200,SIMPLE_HEADER,read(joinpath(js_folder, "jugsawdebug.html")))
    )
    HTTP.register!(r, "GET", "/jugsawirparser.js",
        req->HTTP.Response(200,SIMPLE_HEADER,read(joinpath(js_folder, "jugsawirparser.js")))
    )
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
    js_folder = joinpath(pkgdir(@__MODULE__), "js")
    # web page
    HTTP.register!(r, "GET", "/",
        req->HTTP.Response(200,SIMPLE_HEADER,read(joinpath(js_folder, "jugsawdebug.html")))
    )
    HTTP.register!(r, "GET", "/jugsawirparser.js",
        req->HTTP.Response(200,SIMPLE_HEADER,read(joinpath(js_folder, "jugsawirparser.js")))
    )
    # job
    HTTP.register!(r, "POST", "/v1/proj/{project}/app/{appname}/ver/{version}/func/{fname}",
        req->job_handler(runtime, req)
    )
    # cli-job
    HTTP.register!(r, "POST", "/v1/proj/{project}/app/{appname}/ver/{version}/cli/{fname}",
        req->cli_handler(runtime, req)
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