


<a id='JugsawIR'></a>

<a id='JugsawIR-1'></a>

# JugsawIR


[JugsawIR](JugsawIR.md#JugsawIR) is an intermediate representation (IR) for exposing and using cloud scientific applications. Its grammar is compatible with JSON at the time of writing, however, it might undergo a refactor to support richer features. The final form should be a real programming language for Web Virtual Machine.


Jugsaw IR can represent data, data types, and function calls. The basic rule is representing a Jugsaw object as a JSON object with extra constaints,


1. Integers, floating point numbers, `Nothing`, `Missing`, `UndefInitializer`, `Symbol` and `String` are directly representable.
2. Generic objects are represented by a JSON object with at most two fields: `fields` and `type` (optional).
3. Some objects are specialized, including `Array`, `Tuple`, `Dict`, `DataType`.


<a id=':-Representing-Data'></a>

<a id=':-Representing-Data-1'></a>

## 1: Representing Data


<a id='Generic-Data-Types'></a>

<a id='Generic-Data-Types-1'></a>

### Generic Data Types


```julia
julia> julia2ir(1.0+2im)[1] |> println
{"fields":[1.0,2.0],"type":"Base.Complex{Core.Float64}"}
```


Or equivalently, as


```jugsawir
{"type":"Base.Complex{Core.Float64}","fields":[1.0,2.0]}
```


Or when calling a remote function, one can ommit the `"type"` specification, since the remote already has a copy of data types.


```jugsawir
{"fields":[2,3]}
```


!!! note
    The `julia2ir` function returns a two element tuple, a representation of object, and a [`TypeTable`](@ref) to delare types.



<a id='Customized-Data-Types'></a>

<a id='Customized-Data-Types-1'></a>

### Customized Data Types


To customize a Jugsaw data type for your own data type, the following two functions should be overloaded.


  * [`native2jugsaw`](@ref) is for converting a native Julia object to a Jugsaw compatible object.
  * [`construct_object`](@ref) is for reconstructing the native Julia object from an object of type [`JugsawExpr`](@ref). The return value must have the same data type as the second argument.


<a id='Dictionary'></a>

<a id='Dictionary-1'></a>

#### Dictionary


A dictionary is parsed to a [`JugsawIR.JDict`](@ref) instance, which has two fields `keys` and `vals`.


<a id='Array'></a>

<a id='Array-1'></a>

#### Array


An array is parsed to a [`JugsawIR.JArray`](@ref) instance, which has two fields `size` and `storage`.


<a id=':-Representing-Data-Type'></a>

<a id=':-Representing-Data-Type-1'></a>

## 2: Representing Data Type


An data type is parsed to a [`JugsawIR.JDataType`](@ref) instance, which has three fields `name`, `fieldnames` and `fieldtypes`. For example, to represent a complex number type, we can create the following IR


```julia
julia> julia2ir(ComplexF64)[1] |> println
{"fields":["Base.Complex{Core.Float64}",["re","im"],["Core.Float64","Core.Float64"]],"type":"JugsawIR.TypeSpec"}
```


For convenience, JugsawIR returns a [`TypeTable`](@ref) instance to represent the types used in parsing.


<a id=':-Representing-Function-Call'></a>

<a id=':-Representing-Function-Call-1'></a>

## 3: Representing Function Call


A function call is represented as a Jugsaw object with three fields `fname`, `args` and `kwargs`.


```julia
julia> fc = Call(sin, (2.0,), (;))
sin(2.0; )

julia> julia2ir(fc)[1] |> println
{"fields":[{"fields":[],"type":"Base.sin"},{"fields":[2.0],"type":"Core.Tuple{Core.Float64}"},{"fields":[],"type":"Core.NamedTuple{(), Core.Tuple{}}"}],"type":"JugsawIR.Call{Base.sin, Core.Tuple{Core.Float64}, Core.NamedTuple{(), Core.Tuple{}}}"}
```


It is not different with regular Jugsaw object, except that it can executed when it is used to represent a remote call request.


<a id='The-Grammar'></a>

<a id='The-Grammar-1'></a>

## The Grammar


The grammar of JugsawIR in the EBNF format, which can be parsed by [lark](https://lark-parser.readthedocs.io/en/latest/) in Python, [Lerche.jl](https://github.com/jamesrhester/Lerche.jl) in Julia and hopefully [lark-js](https://pypi.org/project/lark-js/) in Javascript.


```
object: genericobj1
        | genericobj2
        | genericobj3
        | list
        | string
        | number
        | true
        | false
        | null

genericobj1 : "{" "\"fields\"" ":" list "}"
genericobj2 : "{" "\"type\"" ":" ESCAPED_STRING "," "\"fields\"" ":" list "}"
genericobj3 : "{" "\"fields\"" ":" list "," "\"type\"" ":" ESCAPED_STRING "}"

list : "[" [object ("," object)*] "]"
string : ESCAPED_STRING
number : SIGNED_NUMBER
true : "true"
false : "false"
null : "null"

%import common.ESCAPED_STRING
%import common.SIGNED_NUMBER
%import common.WS
%ignore WS
```


<a id='APIs'></a>

<a id='APIs-1'></a>

## APIs

<a id='JugsawIR.Call' href='#JugsawIR.Call'>#</a>
**`JugsawIR.Call`** &mdash; *Type*.



```julia
struct Call{FT, argsT<:Tuple, kwargsT<:NamedTuple}
```

**Fields**

  * `fname::Any`
  * `args::Tuple`
  * `kwargs::NamedTuple`


<a target='_blank' href='https://github.com/Jugsaw/Jugsaw.jl/blob/67fe35adcb19f0ef135dac9c8cd8ecae936fd21d/lib/JugsawIR/src/Core.jl#L10' class='documenter-source'>source</a><br>

<a id='JugsawIR.Graph' href='#JugsawIR.Graph'>#</a>
**`JugsawIR.Graph`** &mdash; *Type*.



```julia
Graph
```

The data type for representing a graph.

**Fields**

  * `nv::Int` is the number of vertices. The vertices are `{1, 2, ..., nv}`.
  * `edges::Matrix{Int}` is a 2 x n matrix, each column is an edge.


<a target='_blank' href='https://github.com/Jugsaw/Jugsaw.jl/blob/67fe35adcb19f0ef135dac9c8cd8ecae936fd21d/lib/JugsawIR/src/typeext.jl#L25-L33' class='documenter-source'>source</a><br>

<a id='JugsawIR.TypeSpec' href='#JugsawIR.TypeSpec'>#</a>
**`JugsawIR.TypeSpec`** &mdash; *Type*.



```julia
struct TypeSpec
```

The type for specifying data type in Jugsaw.

**Fields**

  * `name::String`
  * `structtype::String`
  * `description::String`
  * `fieldnames::Vector{String}`
  * `fieldtypes::Vector{TypeSpec}`
  * `fielddescriptions::Vector{String}`

  * `name` is the name of the type,
  * `structtype` is the type of the JSON3 struct. Please check https://quinnj.github.io/JSON3.jl/dev/#DataTypes
  * `fieldtypes` is the type of the fields. It is a vector of `TypeSpec` instances.

For Array structtype, it is a single element vector of `TypeSpec` instances of the element type.


<a target='_blank' href='https://github.com/Jugsaw/Jugsaw.jl/blob/67fe35adcb19f0ef135dac9c8cd8ecae936fd21d/lib/JugsawIR/src/typespec.jl#L1' class='documenter-source'>source</a><br>


!!! warning "Missing docstring."
    Missing docstring for `native2jugsaw`. Check Documenter's build log for details.



!!! warning "Missing docstring."
    Missing docstring for `construct_object`. Check Documenter's build log for details.


