```@meta
DocTestSetup = quote
    using Jugsaw
end 
```

# Jugsaw

## Chained function call

When Jugsaw server gets a chained function call, like `sin(cos(0.5))`.
The following two tasks will be added to the task queue.
```julia
Call(cos, (0.5,), (;)) -> id1
Call(sin, (object_getter(state_store, id1),), (;))
```
where `->` points to the id of the returned object in the `state_store`.
The `state_store` is a dictionary mapping an object id to its value.
When querying an object from the `state_store`, the program waits for the corresponding task to complete.

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

## APIs

```@autodocs
Modules = [Jugsaw]
Order = [:function, :macro, :type, :module]
```
