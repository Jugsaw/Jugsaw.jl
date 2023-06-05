


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

<a id='Jugsaw.generate_code-Tuple{String, Vararg{Any}}' href='#Jugsaw.generate_code-Tuple{String, Vararg{Any}}'>#</a>
**`Jugsaw.generate_code`** &mdash; *Method*.



```julia
generate_code(lang, endpoint::String, appname::Symbol, fcall::JugsawADT, democall::JugsawIR.Call)
```

Generate code for target language.

**Arguments**

  * `lang` can be a string or an [`AbstractLang`](@ref) instance that specifies the target language.

Please use `subtypes(AbstractLang)` for supported client languages.

  * `endpoint` is the url for service provider, e.g. it can be [https://www.jugsaw.co](https://www.jugsaw.co).
  * `appname` is the application name.
  * `fcall` is a [`JugsawADT`](@ref) that specifies the function call.
  * `democall` is the demo instance of that function call.


<a target='_blank' href='https://github.com/Jugsaw/Jugsaw.jl/blob/aca908e27edada0cdd10857cef0ed1da27f786b5/src/jl/Jugsaw/src/clientcode.jl#L6-L18' class='documenter-source'>source</a><br>

