"""
$TYPEDSIGNATURES

Handle the request of function call and returns a response with job id.

### Request
A JSON payload that specifies the function call as `{"id" : ..., "created_at" : ..., "created_by" : ..., "maxtime" : ..., "fname" : ..., "args" : ..., "kwargs" : ...}`.

### Response
* [Success]: a JSON object `{"job_id" : ...}`.
* [NoDemoException]: a JSON object `{"error" : ...}`.
"""
function job_handler(r::AppRuntime, req::HTTP.Request)
    params = HTTP.getparams(req)
    fname = params["fname"]
    try
        # 1. Find the demo
        if !haskey(r.app.method_demos, fname)
            err = NoDemoException(fname, r.app)
            throw(err)
        end
        demo = r.app.method_demos[fname]
        # 2. Parse job
        jobT = Job{typeof(demo.fcall.fname), typeof(demo.fcall.args), typeof(demo.fcall.kwargs)}
        job = CloudEvents.from_http(req.headers, req.body, jobT).data
        @info "get job: $job"
        # 3. Submit a job
        submitjob!(r, job)
        return HTTP.Response(200, JSON_HEADER, JSON3.write((; job_id=job.id)))
    catch e
        if e isa NoDemoException
            evt = CloudEvents.from_http(req.headers, req.body)
            job_id = evt.data["id"]
            publish_status(r.dapr, JobStatus(id=job_id, status=failed, description=_error_msg(e)))
        else
            showerror(stdout, e, catch_backtrace())
        end
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
    code, status = fetch_status(r.dapr, job_id; timeout=timeout)
    if code != :ok
        return _error_response(ErrorException("can not find any information about target job: $job_id"))
    end
    # starting processing pending succeeded failed canceled
    if status.status == succeeded
        st, ir = load_object_as_ir(r.dapr, job_id; timeout=timeout)
        if st != :ok
            return _error_response(ErrorException("object not ready yet!"))
        elseif st == :timed_out
            return _error_response(TimedOutException(job_id, timeout))
        else
            return HTTP.Response(200, JSON_HEADER, ir)
        end
    elseif status.status == failed
        return _error_response(ErrorException("an error occured! status: $(status)"))
    elseif status.status == canceled
        return _error_response(ErrorException("job has been canceled! status: $(status)"))
    else
        return _error_response(ErrorException("job not ready yet! status: $(status)"))
    end
end

"""
$TYPEDSIGNATURES

Handle the request of getting application specification, including registered function demos and type definitions.

### Response
* [Success]: Jugsaw IR in the form of a JSON object.
"""
function demos_handler(app::AppSpecification)
    return HTTP.Response(200, JSON_HEADER, JSON3.write((; app, typespec=JugsawIR.TypeSpec(typeof(app)))))
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
    # fetch
    HTTP.register!(r, "POST", "/v1/job/{job_id}/result",
        req -> fetch_handler(runtime, req)
    )
    # demos
    HTTP.register!(r, "GET", "/v1/proj/{project}/app/{appname}/ver/{version}/func",
        req -> demos_handler(runtime.app)
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