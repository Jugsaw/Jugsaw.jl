module Server
using HTTP
using JugsawIR
using Dates: now, datetime2unix
using JugsawIR.JSON3, JugsawIR.DocStringExtensions
import CloudEvents
import Revise
import DaprClients
import UUIDs
import ..AppSpecification, ..NoDemoException, .._error_msg, ..TimedOutException, ..GLOBAL_CONFIG

export Job, JobStatus
export AbstractEventService, DaprService, FileEventService, InMemoryEventService, publish_status, fetch_status, save_object, load_object, load_object_as_ir, get_timeout
export AppRuntime, addjob!
export demos_handler, code_handler, fetch_handler, job_handler

include("jobhandler.jl")
include("simpleserver.jl")
include("liveserver.jl")

# Return true if the service is running on a local machine.
# When running in a docker image, the "JUGSAW_SERVER" environment variable should be "DOCKER".
running_locally() = GLOBAL_CONFIG["jugsaw-server"] == "LOCAL"

"""
$(TYPEDSIGNATURES)

Returns the network timeout of the event service access in seconds.
"""
get_timeout() = GLOBAL_CONFIG["network-timeout"]

"""
$(TYPEDSIGNATURES)

Returns the query time interval of the event service in seconds.
"""
get_query_interval() = GLOBAL_CONFIG["query-interval"]

"""
$(TYPEDSIGNATURES)

Serve this application on specified host and port.

### Arguments
* `app` is a [`AppSpecification`](@ref) instance.

### Keyword arguments
* `eventservice` is a [`AbstractEventService`](@ref) instance, which is used to store job status and computed results.
The default value of `eventservice` depends on environment variable "JUGSAW_SERVER".
If the server runs on the localhost, then the value of "JUGSAW_SERVER" should be "LOCAL" or missing, and default value of `eventservice` is `InMemoryEventService()`.
Otherwise if the server runs on a docker container, then the value of "JUGSAW_SERVER" should be something else, and default value of `eventservice` is `DaprService()`.
* `liveupdate` is a boolean variable. If `liveupdate` is true, application will be updated automatically.
The default value of `liveupdate` depends on environment variable "JUGSAW_SERVER".
If the server runs on the localhost, then the value of "JUGSAW_SERVER" should be "LOCAL" or missing, and default value of `liveupdate` is true.
Otherwise if the server runs on a docker container, then the value of "JUGSAW_SERVER" should be something else, and default value of `liveupdate` is false.
* `watched_files` is a list of file paths to watch with `Revise.jl`, the server will restart automatically on the change of watched files if `liveserve` is true.
* `host` is the IP address or url of the host.
* `port` is the port to serve the application.
* `launch_browser` is boolean variable. If both this variable and `liveserve` are true, the default browser will open an html page for end-to-end testing.
* `localurl` is a switch to serve in local mode with a simplified routing table.
In the local mode, the project name and application name are not required in the request url.

### The route table
* ("GET", "/") -> get the index page (for local debugging).
* ("POST", "/v1/proj/{project}/app/{appname}/ver/{version}/func/{fname}") -> call a function and return a job id, please check [`job_handler`](@ref).
* ("POST", "/v1/job/{job_id}/result") -> fetch results with a job id, please check [`fetch_handler`](@ref).
* ("GET", "/v1/proj/{project}/app/{appname}/ver/{version}/func") -> get application information, please check [`demos_handler`](@ref).
* ("GET", "/v1/proj/{project}/app/{appname}/ver/{version}/healthz") -> get the status of current application.
"""
function serve(app::AppSpecification;
        eventservice = running_locally() ? InMemoryEventService() : DaprService(),
        liveupdate::Bool=running_locally(),
        host::String="0.0.0.0",
        port::Int=8088,
        localurl::Bool=false,
        launch_browser::Bool=true,
        watched_files::Vector{String}=String[],
        )
    if liveupdate
        liveserve(app, eventservice; watched_files, host, port, localurl, launch_browser)
    else
        simpleserve(AppRuntime(app, eventservice); host, port, localurl, is_async=false)
    end
end

end