


<a id='Jugsaw.Client'></a>

<a id='Jugsaw.Client-1'></a>

# Jugsaw.Client

<a id='Jugsaw.Client.call-Tuple{Jugsaw.Client.ClientContext, Jugsaw.Client.Demo, Vararg{Any}}' href='#Jugsaw.Client.call-Tuple{Jugsaw.Client.ClientContext, Jugsaw.Client.Demo, Vararg{Any}}'>#</a>
**`Jugsaw.Client.call`** &mdash; *Method*.



```julia
call(
    context::Jugsaw.Client.ClientContext,
    demo::Jugsaw.Client.Demo,
    args...;
    kwargs...
) -> Jugsaw.Client.LazyReturn

```

Launch a function call.


<a target='_blank' href='https://github.com/Jugsaw/Jugsaw.jl/blob/5540be704545bfc349240e1c77ebcf3a9a6d1474/src/jl/Jugsaw/src/client/remotecall.jl#L44' class='documenter-source'>source</a><br>

<a id='Jugsaw.Client.healthz-Tuple{Jugsaw.Client.ClientContext}' href='#Jugsaw.Client.healthz-Tuple{Jugsaw.Client.ClientContext}'>#</a>
**`Jugsaw.Client.healthz`** &mdash; *Method*.



```julia
healthz(context::Jugsaw.Client.ClientContext) -> Any

```

Check the status of the application.


<a target='_blank' href='https://github.com/Jugsaw/Jugsaw.jl/blob/5540be704545bfc349240e1c77ebcf3a9a6d1474/src/jl/Jugsaw/src/client/remotecall.jl#L90' class='documenter-source'>source</a><br>

<a id='Jugsaw.Client.request_app-Tuple{Jugsaw.Client.ClientContext, Symbol}' href='#Jugsaw.Client.request_app-Tuple{Jugsaw.Client.ClientContext, Symbol}'>#</a>
**`Jugsaw.Client.request_app`** &mdash; *Method*.



```julia
request_app(
    context::Jugsaw.Client.ClientContext,
    appname::Symbol
) -> Jugsaw.Client.App

```

Request an application from an endpoint.

**Arguments**

  * `context` is a [`ClientContext`](JugsawClient.md#Jugsaw.Client.ClientContext) instance, which contains contextual information like the endpoint.
  * `appname` specificies the application to be fetched.


<a target='_blank' href='https://github.com/Jugsaw/Jugsaw.jl/blob/5540be704545bfc349240e1c77ebcf3a9a6d1474/src/jl/Jugsaw/src/client/remotecall.jl#L19' class='documenter-source'>source</a><br>

<a id='Jugsaw.Client.App' href='#Jugsaw.Client.App'>#</a>
**`Jugsaw.Client.App`** &mdash; *Type*.



```julia
struct App
```

The Jugsaw application instance.

!!! note
    The `Base.getproperty` function has been overloaded to favor fetching demos. To get fields, please use `app[fieldname]`. For example, to get the application name, one should use `app[:name]`.


**Fields**

  * `name::Symbol`
  * `method_demos::OrderedCollections.OrderedDict{Symbol, Vector{Jugsaw.Client.Demo}}`
  * `type_table::TypeTable`
  * `context::Jugsaw.Client.ClientContext`


<a target='_blank' href='https://github.com/Jugsaw/Jugsaw.jl/blob/5540be704545bfc349240e1c77ebcf3a9a6d1474/src/jl/Jugsaw/src/client/Core.jl#L107' class='documenter-source'>source</a><br>

<a id='Jugsaw.Client.ClientContext' href='#Jugsaw.Client.ClientContext'>#</a>
**`Jugsaw.Client.ClientContext`** &mdash; *Type*.



```julia
mutable struct ClientContext
```

**Fields**

  * `endpoint::String`
  * `localurl::Bool`
  * `project::String`
  * `appname::Symbol`
  * `version::String`
  * `fname::Symbol`


<a target='_blank' href='https://github.com/Jugsaw/Jugsaw.jl/blob/5540be704545bfc349240e1c77ebcf3a9a6d1474/src/jl/Jugsaw/src/client/Core.jl#L1' class='documenter-source'>source</a><br>

<a id='Jugsaw.Client.Demo' href='#Jugsaw.Client.Demo'>#</a>
**`Jugsaw.Client.Demo`** &mdash; *Type*.



```julia
struct Demo
```

**Fields**

  * `fcall::Call`
  * `result::Any`
  * `meta::Dict{String}`


<a target='_blank' href='https://github.com/Jugsaw/Jugsaw.jl/blob/5540be704545bfc349240e1c77ebcf3a9a6d1474/src/jl/Jugsaw/src/client/Core.jl#L18' class='documenter-source'>source</a><br>

<a id='Jugsaw.Client.DemoRef' href='#Jugsaw.Client.DemoRef'>#</a>
**`Jugsaw.Client.DemoRef`** &mdash; *Type*.



```julia
struct DemoRef
```

**Fields**

  * `demo::Jugsaw.Client.Demo`
  * `context::Jugsaw.Client.ClientContext`


<a target='_blank' href='https://github.com/Jugsaw/Jugsaw.jl/blob/5540be704545bfc349240e1c77ebcf3a9a6d1474/src/jl/Jugsaw/src/client/Core.jl#L35' class='documenter-source'>source</a><br>

<a id='Jugsaw.Client.DemoRefs' href='#Jugsaw.Client.DemoRefs'>#</a>
**`Jugsaw.Client.DemoRefs`** &mdash; *Type*.



```julia
struct DemoRefs
```

**Fields**

  * `name::Symbol`
  * `demos::Vector{Jugsaw.Client.Demo}`
  * `context::Jugsaw.Client.ClientContext`


<a target='_blank' href='https://github.com/Jugsaw/Jugsaw.jl/blob/5540be704545bfc349240e1c77ebcf3a9a6d1474/src/jl/Jugsaw/src/client/Core.jl#L63' class='documenter-source'>source</a><br>

<a id='Jugsaw.Client.LazyReturn' href='#Jugsaw.Client.LazyReturn'>#</a>
**`Jugsaw.Client.LazyReturn`** &mdash; *Type*.



```julia
struct LazyReturn
```

A callable lazy result. To fetch the result value, please use `lazyresult()`.

**Fields**

  * `context::Jugsaw.Client.ClientContext`
  * `job_id::String`
  * `demo_result::Any`


<a target='_blank' href='https://github.com/Jugsaw/Jugsaw.jl/blob/5540be704545bfc349240e1c77ebcf3a9a6d1474/src/jl/Jugsaw/src/client/remotecall.jl#L2' class='documenter-source'>source</a><br>

