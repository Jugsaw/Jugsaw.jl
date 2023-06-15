
<a id='Julia-Client'></a>

<a id='Julia-Client-1'></a>

# Julia Client


Check [Python]() and [Javascript]() versions.


Jugsaw's Julia client, or `Jugsaw.Client`, is a submodule of the Julia package [Jugsaw](https://github.com/Jugsaw/Jugsaw). To install Jugsaw, please [open Julia's interactive session (known as REPL)](https://docs.julialang.org/en/v1/manual/getting-started/) and type the following command


```julia
julia> using Pkg; Pkg.add("Jugsaw")
```


<a id='Tutorial'></a>

<a id='Tutorial-1'></a>

## Tutorial


As a first step, you need to decide which remote to execute a function. By default, it uses the [Jugsaw Cloud]().


```julia
remote = 
```


<a id='Advanced-features'></a>

<a id='Advanced-features-1'></a>

## Advanced features


Advanced features require you to [setup your Jugsaw account]().


<a id='Using-shared-nodes'></a>

<a id='Using-shared-nodes-1'></a>

### Using shared nodes


The following is an example of launching a Jugsaw app on the shared endpoint with the Julia language (we have multiple clients).


```julia
julia> using JugsawClient

julia> msg = open(JugsawClient.SharedNode(
                endpoint="https://api.jugsaw.co"),
                app="hello-world",
                uuid="79dccd12-cad8-11ed-387a-f9e5b0f14a94",
                keep=true) do app
        app.greet("World")
    end;

julia> println(msg["result"]) # the result
Hello World!

julia> println(msg["uuid"])   # the instance id
"79dccd12-cad8-11ed-387a-f9e5b0f14a94"

julia> println(msg["time"])   # time in seconds
0.001

julia> println(msg["exit code"])   # exit code
0
```


**Rules**


  * If uuid is not specified, then the function will be executed on the shared instance (if any).
  * If uuid is specified, then the specific instance will be used (may throw `InstanceNotExistError`).
  * Unless `keep` is true, an instance will be killed after being inactive for 20min.


A free tier user can keep at most 10 instances at the same time. Please go to the [control panel]() to free some instances if you see a `InstanceQuotaError` or subscribe our [Jugsaw premium]().


<a id='Using-cluster-nodes'></a>

<a id='Using-cluster-nodes-1'></a>

### Using cluster nodes


The following is an example of launching a Jugsaw app on a cluster with Julia language (we have multiple clients).


```julia
julia> using JugsawClient

julia> msg = open(JugsawClient.ClusterNode(
                endpoint="https://api.hkust-cluster.edu.cn"),
                app="hello-world",
                ncpu = 5,
                ngpu = 1,
                usempi = false,
                usecuda = true,
                timelimit = 3600,   # in seconds
                ) do app
        app.greet("World")
    end;
[ Info: You can manage your job with this URI: https://api.hkust-cluster.edu.cn/monitor/79dccd12-cad8-11ed-387a-f9e5b0f14a94/

julia> println(msg["exit code"])   # exit code
0
```


**Rules**


  * Cluster Jugsaw call is stateless.
  * There might be an overhead in using clusters. Cluster pull the reqested app from `jugsaw.co` to local, create a `singularity` instance, and launch the job.
  * The result is not returned directly, instead, one should use the returned URI to access the result and manage the jobs.


<a id='Chained-function-call'></a>

<a id='Chained-function-call-1'></a>

## Chained function call


When Jugsaw server gets a chained function call, like `sin(cos(0.5))`. The following two tasks will be added to the task queue.


```julia
Call(cos, (0.5,), (;)) -> id1
Call(sin, (object_getter(state_store, id1),), (;))
```


where `->` points to the id of the returned object in the `state_store`. The `state_store` is a dictionary mapping an object id to its value. When querying an object from the `state_store`, the program waits for the corresponding task to complete.


`object_getter(id)` returns a `Call` instance with the following definition


```julia
function object_getter(state_store::StateStore, object_id::String)
    Call((s, id)->Meta.parse(Base.getindex(s, id)), (state_store, object_id), (;))
end
```


The nested `Call` is then executed by the `JugsawIR.fevalself` with the following steps


1. `sin` function is triggered,
2. while rendering the arguments of `sin`, the object getter(`Call`) will trigger the `state_store[id1]`,
3. wait for the `cos` function to complete,
4. with the returned object, execute the `sin` function.

