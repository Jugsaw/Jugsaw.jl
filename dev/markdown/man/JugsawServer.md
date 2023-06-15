


<a id='Jugsaw.Server'></a>

<a id='Jugsaw.Server-1'></a>

# Jugsaw.Server

<a id='Jugsaw.Server.code_handler-Tuple{HTTP.Messages.Request, AppSpecification}' href='#Jugsaw.Server.code_handler-Tuple{HTTP.Messages.Request, AppSpecification}'>#</a>
**`Jugsaw.Server.code_handler`** &mdash; *Method*.



```julia
code_handler(
    req::HTTP.Messages.Request,
    app::AppSpecification
) -> HTTP.Messages.Response

```

Handle the request of generating the API for calling from a specific client language.

**Response**

  * [Success]: a JSON object with requested API code `{"code" : ...}`.
  * [NoDemoException]: a JSON object `{"error" : ...}`.
  * [ErrorException]: a JSON object `{"error" : ...}`.


<a target='_blank' href='https://github.com/Jugsaw/Jugsaw.jl/blob/6015de0a47fd0e1fa3315929fbf489183839d5ea/src/jl/Jugsaw/src/server/simpleserver.jl#L75' class='documenter-source'>source</a><br>

<a id='Jugsaw.Server.demos_handler-Tuple{AppSpecification}' href='#Jugsaw.Server.demos_handler-Tuple{AppSpecification}'>#</a>
**`Jugsaw.Server.demos_handler`** &mdash; *Method*.



```julia
demos_handler(
    app::AppSpecification
) -> HTTP.Messages.Response

```

Handle the request of getting application specification, including registered function demos and type definitions.

**Response**

  * [Success]: Jugsaw IR in the form of a JSON object.


<a target='_blank' href='https://github.com/Jugsaw/Jugsaw.jl/blob/6015de0a47fd0e1fa3315929fbf489183839d5ea/src/jl/Jugsaw/src/server/simpleserver.jl#L61' class='documenter-source'>source</a><br>

<a id='Jugsaw.Server.fetch_handler-Tuple{Jugsaw.Server.AppRuntime, HTTP.Messages.Request}' href='#Jugsaw.Server.fetch_handler-Tuple{Jugsaw.Server.AppRuntime, HTTP.Messages.Request}'>#</a>
**`Jugsaw.Server.fetch_handler`** &mdash; *Method*.



```julia
fetch_handler(
    r::Jugsaw.Server.AppRuntime,
    req::HTTP.Messages.Request
) -> HTTP.Messages.Response

```

Handle the request of fetching computed results and return a response with job id.

**Request**

A JSON payload that specifies the job id as `{"job_id" : ...}`.

**Response**

  * [Success]: Jugsaw IR in the form of JSON payload.
  * [TimedOutException]: a JSON object `{"error" : ...}`.
  * [ErrorException]: a JSON object `{"error" : ...}`.


<a target='_blank' href='https://github.com/Jugsaw/Jugsaw.jl/blob/6015de0a47fd0e1fa3315929fbf489183839d5ea/src/jl/Jugsaw/src/server/simpleserver.jl#L32' class='documenter-source'>source</a><br>

<a id='Jugsaw.Server.fetch_status' href='#Jugsaw.Server.fetch_status'>#</a>
**`Jugsaw.Server.fetch_status`** &mdash; *Function*.



```julia
fetch_status(dapr::AbstractEventService, job_id::String; timeout::Real=get_timeout()) -> (status_code, status)
```

Get the status of a job. The return value is a tuple with the following two elements

  * `status_code` is a symbol to indicate the status query result, which can be `:ok` or `:timed_out`
  * `status` is a `JobStatus` object if the `status_code` is `:ok`, otherwise, is `nothing`.


<a target='_blank' href='https://github.com/Jugsaw/Jugsaw.jl/blob/6015de0a47fd0e1fa3315929fbf489183839d5ea/src/jl/Jugsaw/src/server/jobhandler.jl#L130-L136' class='documenter-source'>source</a><br>

<a id='Jugsaw.Server.get_query_interval-Tuple{}' href='#Jugsaw.Server.get_query_interval-Tuple{}'>#</a>
**`Jugsaw.Server.get_query_interval`** &mdash; *Method*.



```julia
get_query_interval() -> Any

```

Returns the query time interval of the event service in seconds.


<a target='_blank' href='https://github.com/Jugsaw/Jugsaw.jl/blob/6015de0a47fd0e1fa3315929fbf489183839d5ea/src/jl/Jugsaw/src/server/server.jl#L38' class='documenter-source'>source</a><br>

<a id='Jugsaw.Server.get_timeout-Tuple{}' href='#Jugsaw.Server.get_timeout-Tuple{}'>#</a>
**`Jugsaw.Server.get_timeout`** &mdash; *Method*.



```julia
get_timeout() -> Any

```

Returns the network timeout of the event service access in seconds.


<a target='_blank' href='https://github.com/Jugsaw/Jugsaw.jl/blob/6015de0a47fd0e1fa3315929fbf489183839d5ea/src/jl/Jugsaw/src/server/server.jl#L31' class='documenter-source'>source</a><br>

<a id='Jugsaw.Server.job_handler-Tuple{Jugsaw.Server.AppRuntime, HTTP.Messages.Request}' href='#Jugsaw.Server.job_handler-Tuple{Jugsaw.Server.AppRuntime, HTTP.Messages.Request}'>#</a>
**`Jugsaw.Server.job_handler`** &mdash; *Method*.



```julia
job_handler(
    r::Jugsaw.Server.AppRuntime,
    req::HTTP.Messages.Request
) -> HTTP.Messages.Response

```

Handle the request of function call and returns a response with job id.

**Request**

A Jugsaw IR that corresponds to a [`JobSpec`](JugsawServer.md#Jugsaw.Server.JobSpec) instance.

**Response**

  * [Success]: a JSON object `{"job_id" : ...}`.
  * [NoDemoException]: a JSON object `{"error" : ...}`.


<a target='_blank' href='https://github.com/Jugsaw/Jugsaw.jl/blob/6015de0a47fd0e1fa3315929fbf489183839d5ea/src/jl/Jugsaw/src/server/simpleserver.jl#L1' class='documenter-source'>source</a><br>

<a id='Jugsaw.Server.load_object-Tuple{Jugsaw.Server.AbstractEventService, AbstractString, Any}' href='#Jugsaw.Server.load_object-Tuple{Jugsaw.Server.AbstractEventService, AbstractString, Any}'>#</a>
**`Jugsaw.Server.load_object`** &mdash; *Method*.



```julia
load_object(dapr::AbstractEventService, job_id::AbstractString, resdemo; timeout::Real) -> (status_code, object)
```

Load an object to the main memory. The return value is a tuple with the following two elements

  * `status_code` is a symbol to indicate the status query result, which can be `:ok` or `:timed_out`
  * `status` is an object if the `status_code` is `:ok`, otherwise, is `nothing`.

The keyword argument `timeout` is should be greater than the expected job run time.


<a target='_blank' href='https://github.com/Jugsaw/Jugsaw.jl/blob/6015de0a47fd0e1fa3315929fbf489183839d5ea/src/jl/Jugsaw/src/server/jobhandler.jl#L98-L106' class='documenter-source'>source</a><br>

<a id='Jugsaw.Server.load_object_as_ir' href='#Jugsaw.Server.load_object_as_ir'>#</a>
**`Jugsaw.Server.load_object_as_ir`** &mdash; *Function*.



```julia
load_object_as_ir(dapr::AbstractEventService, job_id::AbstractString; timeout::Real) -> (status_code, ir)
```

Similar to [`load_object`](JugsawServer.md#Jugsaw.Server.load_object-Tuple{Jugsaw.Server.AbstractEventService, AbstractString, Any}), but returns a Jugsaw IR instead. An object demo is not required.


<a target='_blank' href='https://github.com/Jugsaw/Jugsaw.jl/blob/6015de0a47fd0e1fa3315929fbf489183839d5ea/src/jl/Jugsaw/src/server/jobhandler.jl#L115-L119' class='documenter-source'>source</a><br>

<a id='Jugsaw.Server.open_in_default_browser-Tuple{AbstractString}' href='#Jugsaw.Server.open_in_default_browser-Tuple{AbstractString}'>#</a>
**`Jugsaw.Server.open_in_default_browser`** &mdash; *Method*.



```julia
open_in_default_browser(url)
```

Open a URL in the ambient default browser.

Note: this was copied from `LiveServer.jl`, and the original copy is from `Pluto.jl`.


<a target='_blank' href='https://github.com/Jugsaw/Jugsaw.jl/blob/6015de0a47fd0e1fa3315929fbf489183839d5ea/src/jl/Jugsaw/src/server/liveserver.jl#L27-L33' class='documenter-source'>source</a><br>

<a id='Jugsaw.Server.publish_status' href='#Jugsaw.Server.publish_status'>#</a>
**`Jugsaw.Server.publish_status`** &mdash; *Function*.



```julia
publish_status(dapr::AbstractEventService, job_status::JobStatus) -> nothing
```

Publish the status of a job to the event service. The published event can be accessed with [`fetch_status`](JugsawServer.md#Jugsaw.Server.fetch_status) function.


<a target='_blank' href='https://github.com/Jugsaw/Jugsaw.jl/blob/6015de0a47fd0e1fa3315929fbf489183839d5ea/src/jl/Jugsaw/src/server/jobhandler.jl#L122-L127' class='documenter-source'>source</a><br>

<a id='Jugsaw.Server.save_object' href='#Jugsaw.Server.save_object'>#</a>
**`Jugsaw.Server.save_object`** &mdash; *Function*.



```julia
save_object(dapr::AbstractEventService, job_id::AbstractString, res) -> nothing
```

Save an object to the event service in the form of local or web storage. The stored object can be loaded with [`load_object`](JugsawServer.md#Jugsaw.Server.load_object-Tuple{Jugsaw.Server.AbstractEventService, AbstractString, Any}) function.


<a target='_blank' href='https://github.com/Jugsaw/Jugsaw.jl/blob/6015de0a47fd0e1fa3315929fbf489183839d5ea/src/jl/Jugsaw/src/server/jobhandler.jl#L90-L95' class='documenter-source'>source</a><br>

<a id='Jugsaw.Server.serve-Tuple{AppSpecification}' href='#Jugsaw.Server.serve-Tuple{AppSpecification}'>#</a>
**`Jugsaw.Server.serve`** &mdash; *Method*.



```julia
serve(
    app::AppSpecification;
    eventservice,
    liveupdate,
    host,
    port,
    localurl,
    launch_browser,
    watched_files
) -> Union{Nothing, Task, HTTP.Servers.Server{HTTP.Servers.Listener{Nothing, Sockets.TCPServer}}}

```

Serve this application on specified host and port.

**Arguments**

  * `app` is a [`AppSpecification`](Jugsaw.md#Jugsaw.AppSpecification) instance.

**Keyword arguments**

  * `eventservice` is a [`AbstractEventService`](JugsawServer.md#Jugsaw.Server.AbstractEventService) instance, which is used to store job status and computed results.

The default value of `eventservice` depends on environment variable "JUGSAW*SERVER". If the server runs on the localhost, then the value of "JUGSAW*SERVER" should be "LOCAL" or missing, and default value of `eventservice` is `InMemoryEventService()`. Otherwise if the server runs on a docker container, then the value of "JUGSAW_SERVER" should be something else, and default value of `eventservice` is `DaprService()`.

  * `liveupdate` is a boolean variable. If `liveupdate` is true, application will be updated automatically.

The default value of `liveupdate` depends on environment variable "JUGSAW*SERVER". If the server runs on the localhost, then the value of "JUGSAW*SERVER" should be "LOCAL" or missing, and default value of `liveupdate` is true. Otherwise if the server runs on a docker container, then the value of "JUGSAW_SERVER" should be something else, and default value of `liveupdate` is false.

  * `watched_files` is a list of file paths to watch with `Revise.jl`, the server will restart automatically on the change of watched files if `liveserve` is true.
  * `host` is the IP address or url of the host.
  * `port` is the port to serve the application.
  * `launch_browser` is boolean variable. If both this variable and `liveserve` are true, the default browser will open an html page for end-to-end testing.
  * `localurl` is a switch to serve in local mode with a simplified routing table.

In the local mode, the project name and application name are not required in the request url.

**The route table**

  * ("GET", "/") -> get the index page (for local debugging).
  * ("POST", "/v1/proj/{project}/app/{appname}/ver/{version}/func/{fname}") -> call a function and return a job id, please check [`job_handler`](JugsawServer.md#Jugsaw.Server.job_handler-Tuple{Jugsaw.Server.AppRuntime, HTTP.Messages.Request}).
  * ("POST", "/v1/job/{job*id}/result") -> fetch results with a job id, please check [`fetch*handler`](@ref).
  * ("GET", "/v1/proj/{project}/app/{appname}/ver/{version}/func") -> get application information, please check [`demos_handler`](JugsawServer.md#Jugsaw.Server.demos_handler-Tuple{AppSpecification}).
  * ("GET", "/v1/proj/{project}/app/{appname}/ver/{version}/func/{fname}/api/{lang}") -> get the API call for a client language, please check [`code_handler`](JugsawServer.md#Jugsaw.Server.code_handler-Tuple{HTTP.Messages.Request, AppSpecification}).
  * ("GET", "/v1/proj/{project}/app/{appname}/ver/{version}/healthz") -> get the status of current application.


<a target='_blank' href='https://github.com/Jugsaw/Jugsaw.jl/blob/6015de0a47fd0e1fa3315929fbf489183839d5ea/src/jl/Jugsaw/src/server/server.jl#L45' class='documenter-source'>source</a><br>

<a id='Jugsaw.Server.simpleserve-Tuple{Jugsaw.Server.AppRuntime}' href='#Jugsaw.Server.simpleserve-Tuple{Jugsaw.Server.AppRuntime}'>#</a>
**`Jugsaw.Server.simpleserve`** &mdash; *Method*.



```julia
simpleserve(runtime::AppRuntime; is_async=false, host="0.0.0.0", port=8088, localurl=false)
```

Serve this application on specified host and port.

**Arguments**

  * `runtime` is an [`AppRuntime`](JugsawServer.md#Jugsaw.Server.AppRuntime) instance.

**Keyword arguments**

  * `is_async` is a switch to turn on the asynchronous mode for debugging.
  * `host` is the IP address or url of the host.
  * `port` is the port to serve the application.
  * `localurl` is a switch to serve in local mode with a simplified routing table.

In the local mode, the project name and application name are not required in the request url.


<a target='_blank' href='https://github.com/Jugsaw/Jugsaw.jl/blob/6015de0a47fd0e1fa3315929fbf489183839d5ea/src/jl/Jugsaw/src/server/simpleserver.jl#L162-L176' class='documenter-source'>source</a><br>

<a id='Jugsaw.Server.AbstractEventService' href='#Jugsaw.Server.AbstractEventService'>#</a>
**`Jugsaw.Server.AbstractEventService`** &mdash; *Type*.



```julia
AbstractEventService
```

The abstract type for event service. Its concrete subtypes include

  * [`DaprService`](JugsawServer.md#Jugsaw.Server.DaprService)
  * [`FileEventService`](JugsawServer.md#Jugsaw.Server.FileEventService)
  * [`InMemoryEventService`](JugsawServer.md#Jugsaw.Server.InMemoryEventService)

**Required Interfaces**

  * [`publish_status`](JugsawServer.md#Jugsaw.Server.publish_status)
  * [`fetch_status`](JugsawServer.md#Jugsaw.Server.fetch_status)
  * [`save_object`](JugsawServer.md#Jugsaw.Server.save_object)
  * [`load_object`](JugsawServer.md#Jugsaw.Server.load_object-Tuple{Jugsaw.Server.AbstractEventService, AbstractString, Any})
  * [`load_object_as_ir`](JugsawServer.md#Jugsaw.Server.load_object_as_ir)


<a target='_blank' href='https://github.com/Jugsaw/Jugsaw.jl/blob/6015de0a47fd0e1fa3315929fbf489183839d5ea/src/jl/Jugsaw/src/server/jobhandler.jl#L73-L87' class='documenter-source'>source</a><br>

<a id='Jugsaw.Server.AppRuntime' href='#Jugsaw.Server.AppRuntime'>#</a>
**`Jugsaw.Server.AppRuntime`** &mdash; *Type*.



```julia
struct AppRuntime{ES<:Jugsaw.Server.AbstractEventService}
```

The application instance wrapped with run time information.

**Fields**

  * `app` is a [`AppSpecification`](Jugsaw.md#Jugsaw.AppSpecification) instance.
  * `dapr` is a [`AbstractEventService`](JugsawServer.md#Jugsaw.Server.AbstractEventService) instance for handling result storing and job status updating.
  * `channel` is a [channel](https://docs.julialang.org/en/v1/base/parallel/#Channels) of jobs to be processed.


<a target='_blank' href='https://github.com/Jugsaw/Jugsaw.jl/blob/6015de0a47fd0e1fa3315929fbf489183839d5ea/src/jl/Jugsaw/src/server/jobhandler.jl#L308' class='documenter-source'>source</a><br>

<a id='Jugsaw.Server.DaprService' href='#Jugsaw.Server.DaprService'>#</a>
**`Jugsaw.Server.DaprService`** &mdash; *Type*.



```julia
DaprService <: AbstractEventService
```

Dapr event service for storing and fetching events and results. Please check [`AbstractEventService`](JugsawServer.md#Jugsaw.Server.AbstractEventService) for implemented interfaces.


<a target='_blank' href='https://github.com/Jugsaw/Jugsaw.jl/blob/6015de0a47fd0e1fa3315929fbf489183839d5ea/src/jl/Jugsaw/src/server/jobhandler.jl#L139-L144' class='documenter-source'>source</a><br>

<a id='Jugsaw.Server.FileEventService' href='#Jugsaw.Server.FileEventService'>#</a>
**`Jugsaw.Server.FileEventService`** &mdash; *Type*.



```julia
FileEventService <: AbstractEventService
```

Mocked event service for storing and fetching events and results from the local file system. Please check [`AbstractEventService`](JugsawServer.md#Jugsaw.Server.AbstractEventService) for implemented interfaces.


<a target='_blank' href='https://github.com/Jugsaw/Jugsaw.jl/blob/6015de0a47fd0e1fa3315929fbf489183839d5ea/src/jl/Jugsaw/src/server/jobhandler.jl#L165-L170' class='documenter-source'>source</a><br>

<a id='Jugsaw.Server.InMemoryEventService' href='#Jugsaw.Server.InMemoryEventService'>#</a>
**`Jugsaw.Server.InMemoryEventService`** &mdash; *Type*.



```julia
struct InMemoryEventService <: Jugsaw.Server.AbstractEventService
```

An event service for storing and fetching events and results from the the main memory. Please check [`AbstractEventService`](JugsawServer.md#Jugsaw.Server.AbstractEventService) for implemented interfaces.

**Fields**

  * `print_event::Bool`
  * `object_store::Dict{String, Any}`
  * `status_store::Dict{String, Jugsaw.Server.JobStatus}`


<a target='_blank' href='https://github.com/Jugsaw/Jugsaw.jl/blob/6015de0a47fd0e1fa3315929fbf489183839d5ea/src/jl/Jugsaw/src/server/jobhandler.jl#L249' class='documenter-source'>source</a><br>

<a id='Jugsaw.Server.Job' href='#Jugsaw.Server.Job'>#</a>
**`Jugsaw.Server.Job`** &mdash; *Type*.



```julia
struct Job
```

A resolved job can be queued and executed in a `AppRuntime`.

**Fields**

  * `id::String`
  * `created_at::Float64`
  * `created_by::String`
  * `maxtime::Float64`
  * `demo::JugsawDemo`
  * `args::Tuple`
  * `kwargs::NamedTuple`


<a target='_blank' href='https://github.com/Jugsaw/Jugsaw.jl/blob/6015de0a47fd0e1fa3315929fbf489183839d5ea/src/jl/Jugsaw/src/server/jobhandler.jl#L37' class='documenter-source'>source</a><br>

<a id='Jugsaw.Server.JobSpec' href='#Jugsaw.Server.JobSpec'>#</a>
**`Jugsaw.Server.JobSpec`** &mdash; *Type*.



```julia
struct JobSpec
```

A job with function payload specified as a [`JugsawADT`](JugsawIR.md#JugsawIR.JugsawADT).

**Fields**

  * `id::String`
  * `created_at::Float64`
  * `created_by::String`
  * `maxtime::Float64`
  * `fname::String`
  * `args::JugsawADT`
  * `kwargs::JugsawADT`

Here `id` is the job id that used to store and fetch computed results.


<a target='_blank' href='https://github.com/Jugsaw/Jugsaw.jl/blob/6015de0a47fd0e1fa3315929fbf489183839d5ea/src/jl/Jugsaw/src/server/jobhandler.jl#L14' class='documenter-source'>source</a><br>

<a id='Jugsaw.Server.JobStatus' href='#Jugsaw.Server.JobStatus'>#</a>
**`Jugsaw.Server.JobStatus`** &mdash; *Type*.



```julia
struct JobStatus
```

A job status that can be pubished to [`AbstractEventService`](JugsawServer.md#Jugsaw.Server.AbstractEventService).

**Fields**

  * `id::String`
  * `status::Jugsaw.Server.JobStatusEnum`
  * `timestamp::Float64`
  * `description::String`


<a target='_blank' href='https://github.com/Jugsaw/Jugsaw.jl/blob/6015de0a47fd0e1fa3315929fbf489183839d5ea/src/jl/Jugsaw/src/server/jobhandler.jl#L58' class='documenter-source'>source</a><br>

