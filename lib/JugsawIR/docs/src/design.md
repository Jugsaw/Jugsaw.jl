# Jugsaw Type System
The goal of Jugsaw Type System (JTU) is to simplify the definition and display of arguments.

> Why not using JSON schema?
> JSON schema is designed for sophisticated input verification.
> In our case, the application rubustness of developer applications is not the first priority, the easy to use is much more important.
> The rubustness of services are guranteed by containerization.

It may have constraint specification as bellow.
```json
{
    "name" : "x",
    "type" : "Int",
    "min" : 2,
    "max" : 5,
    "style" : "input",
    "description" : "this is a number."
}
```

To configure the parameter display in the Jugsaw application file, one can use the `JugsawDev.ui_configure` function.
```julia
ui_configure(greet, :x,
    min = 2,
    max = 5,
    style = "input",
    decription = "this is a number"
)
```
NOTE: `configure` is only for the web display purpose.
We do not do validation at the server side, developer has to handle it properly in his own function.

## Elementary types in JSON Schema
* string -> String
* number -> Float64
* integer -> Int64
* object -> NamedTuple{names, T}
* array -> Array{T}
* boolean -> Bool
* null -> Nothing

## Extended types

### Generic Type
```json
{
    "__type__" : "typename",
    "field1" : 2.3,
    "field2" : "some string"
}
```

### Symbol
```json
{
    "__type__" : "Symbol",
    "data" : "xxz"
}
```

### Complex
```json
{
    "__type__" : "Complex{Float64}",
    "im" : 2.0,
    "re" : 4.0
}
```

### Graph
```json
{
    "__type__" : "Graph",
    "nv" : 3,
    "edges" : {
        "__type__" : "Array{Int64}",
        "size": [2, 2],
        "data" : [1,2,2,3]
    }
}
```
Array data has type `Union{Payload, Array{T,N} where {T,N}}`.

### Payload
```json
{
    "__type__" : "Payload",
    "uri" : "https://www.google.com"
}
```

### Sparse matrix
```json
{
    "__type__" : "SparseMatrixCSC{Float64, Int64}",
    "colptr" : [1, 2, 4, 5],
    "rowval" : [1, 4, 2, 3],
    "nzval" : [0.2, 3.0, 4.0, 2.0],
    "m" : 3,
    "n" : 3
}
```

### Array
```json
{
    "__type__" : "Array{Int64}",
    "size" : [2, 3],
    "data" : [2, 3, 3, 4]
}
```

NOTE: data does not contain type or shape information.

### Tuple
```json
{
    "__type__" : "Tuple{Int64, String}",
    "data" : [2, "Japanese"]
}
```

### NamedTuple
```json
{
    "__type__" : "NamedTuple{(:a, :b), Tuple{Int64, Int64}}",
    "a" : 2,
    "b" : 5
}
```

### Tree
```json
{
    "__type__" : "Tree{Int64}",
    "siblings" : [
        {
            "__type__" : "Tree{Int64}",
            "data" : 2
        }
    ],
    "data" : null
}
```
