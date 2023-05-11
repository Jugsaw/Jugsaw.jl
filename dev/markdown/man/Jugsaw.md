


<a id='Jugsaw'></a>

<a id='Jugsaw-1'></a>

# Jugsaw


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


<a id='APIs'></a>

<a id='APIs-1'></a>

## APIs

<a id='Jugsaw.activate-Tuple{AppRuntime, JugsawADT, String}' href='#Jugsaw.activate-Tuple{AppRuntime, JugsawADT, String}'>#</a>
**`Jugsaw.activate`** &mdash; *Method*.



Try to activate an actor. If the actor of `actor_id` does not exist yet, a new one is created based on the registered `ActorFactor` of `actor_type`. Note that the actor may be configured to recover from its lastest state snapshot.


<a target='_blank' href='https://github.com/Jugsaw/Jugsaw.jl/blob/3c3f9c5ad8cba8eceb24189dd52c00415044b108/src/jl/Jugsaw/src/server.jl#L71-L75' class='documenter-source'>source</a><br>

<a id='Jugsaw.deactivate!-Tuple{AppRuntime, HTTP.Messages.Request}' href='#Jugsaw.deactivate!-Tuple{AppRuntime, HTTP.Messages.Request}'>#</a>
**`Jugsaw.deactivate!`** &mdash; *Method*.



Remove idle actors. Actors may be configure to persistent its current state.


<a target='_blank' href='https://github.com/Jugsaw/Jugsaw.jl/blob/3c3f9c5ad8cba8eceb24189dd52c00415044b108/src/jl/Jugsaw/src/server.jl#L155-L157' class='documenter-source'>source</a><br>

<a id='Jugsaw.fetch-Tuple{AppRuntime, HTTP.Messages.Request}' href='#Jugsaw.fetch-Tuple{AppRuntime, HTTP.Messages.Request}'>#</a>
**`Jugsaw.fetch`** &mdash; *Method*.



This is just a workaround. In the future, users should fetch results from StateStore directly.


<a target='_blank' href='https://github.com/Jugsaw/Jugsaw.jl/blob/3c3f9c5ad8cba8eceb24189dd52c00415044b108/src/jl/Jugsaw/src/server.jl#L171-L173' class='documenter-source'>source</a><br>

<a id='Jugsaw.Actor' href='#Jugsaw.Actor'>#</a>
**`Jugsaw.Actor`** &mdash; *Type*.



Describe current status of an actor.


<a target='_blank' href='https://github.com/Jugsaw/Jugsaw.jl/blob/3c3f9c5ad8cba8eceb24189dd52c00415044b108/src/jl/Jugsaw/src/server.jl#L12-L14' class='documenter-source'>source</a><br>

