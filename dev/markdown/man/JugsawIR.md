


<a id='JugsawIR'></a>

<a id='JugsawIR-1'></a>

# JugsawIR


[JugsawIR](JugsawIR.md#JugsawIR) is an intermediate representation (IR) for exposing and using cloud scientific applications. Its grammar is compatible with JSON at the time of writing, however, it might undergo a refactor to support richer features. The final form should be a real programming language for Web Virtual Machine.


Jugsaw IR can represent data, data types, and function calls. The basic rule is representing a Jugsaw object as a JSON object with extra constaints,


1. Integers, floating point numbers, `Nothing`, `Missing`, `UndefInitializer`, `Symbol` and `String` are directly representable.
2. Generic objects are represented by a JSON object with at most two fields: `fields` and `type` (optional).
3. Some objects are specialized, including `Array`, `Tuple`, `Dict`, `DataType` and `Enum`.


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
    The `julia2ir` function returns a two element tuple, a representation of object, and a [`TypeTable`](JugsawIR.md#JugsawIR.TypeTable) to delare types.



<a id='Customized-Data-Types'></a>

<a id='Customized-Data-Types-1'></a>

### Customized Data Types


To customize a Jugsaw data type for your own data type, the following two functions should be overloaded.


  * [`native2jugsaw`](@ref) is for converting a native Julia object to a Jugsaw compatible object.
  * [`construct_object`](@ref) is for reconstructing the native Julia object from an object of type [`JugsawADT`](JugsawIR.md#JugsawIR.JugsawADT). The return value must have the same data type as the second argument.


<a id='Dictionary'></a>

<a id='Dictionary-1'></a>

#### Dictionary


A dictionary is parsed to a [`JugsawIR.JDict`](JugsawIR.md#JugsawIR.JDict) instance, which has two fields `keys` and `vals`.


<a id='Array'></a>

<a id='Array-1'></a>

#### Array


An array is parsed to a [`JugsawIR.JArray`](JugsawIR.md#JugsawIR.JArray) instance, which has two fields `size` and `storage`.


<a id='Enum'></a>

<a id='Enum-1'></a>

#### Enum


An enum instance is parsed to a [`JugsawIR.JEnum`](JugsawIR.md#JugsawIR.JEnum) instance, which has three fields `kind`, `value` and `options`.


<a id=':-Representing-Data-Type'></a>

<a id=':-Representing-Data-Type-1'></a>

## 2: Representing Data Type


An data type is parsed to a [`JugsawIR.JDataType`](JugsawIR.md#JugsawIR.JDataType) instance, which has three fields `name`, `fieldnames` and `fieldtypes`. For example, to represent a complex number type, we can create the following IR


```julia
julia> julia2ir(ComplexF64)[1] |> println
{"fields":["Base.Complex{Core.Float64}",["re","im"],["Core.Float64","Core.Float64"]],"type":"JugsawIR.JDataType"}
```


For convenience, JugsawIR returns a [`TypeTable`](JugsawIR.md#JugsawIR.TypeTable) instance to represent the types used in parsing.


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

<a id='JugsawIR.construct_object' href='#JugsawIR.construct_object'>#</a>
**`JugsawIR.construct_object`** &mdash; *Function*.



```julia
construct_object(adt::JugsawADT, demo_object)
```

Reconstruct the native Julia object from an object of type [`JugsawADT`](JugsawIR.md#JugsawIR.JugsawADT). The return value must have the same data type as the second argument.


<a target='_blank' href='https://github.com/Jugsaw/Jugsaw.jl/blob/39df1bcf19f70c7211868d09cdfe98f3762e0b5e/src/jl/JugsawIR/src/extendedtypes.jl#L9-L14' class='documenter-source'>source</a><br>

<a id='JugsawIR.ir2julia-Tuple{String, Any}' href='#JugsawIR.ir2julia-Tuple{String, Any}'>#</a>
**`JugsawIR.ir2julia`** &mdash; *Method*.



```julia
ir2julia(str::String, demo) -> Any

```

Convert Jugsaw IR to julia object, given a demo object as a reference. Please check [`julia2ir`](JugsawIR.md#JugsawIR.julia2ir-Tuple{Any}) for the inverse map.

**Examples**

```julia-repl
julia> JugsawIR.ir2julia("{\"fields\" : [3, 4]}", 1+2im)
3 + 4im
```


<a target='_blank' href='https://github.com/Jugsaw/Jugsaw.jl/blob/39df1bcf19f70c7211868d09cdfe98f3762e0b5e/src/jl/JugsawIR/src/ir.jl#L3' class='documenter-source'>source</a><br>

<a id='JugsawIR.julia2ir-Tuple{Any}' href='#JugsawIR.julia2ir-Tuple{Any}'>#</a>
**`JugsawIR.julia2ir`** &mdash; *Method*.



```julia
julia2ir(obj) -> Tuple{Any, Any}

```

Convert julia object to Jugsaw IR and a type table, where the type table is a special Jugsaw IR that stores the type definitions. Please check [`ir2julia`](JugsawIR.md#JugsawIR.ir2julia-Tuple{String, Any}) for the inverse map.

**Examples**

```julia-repl
julia> ir, typetable = JugsawIR.julia2ir(1+2im);

julia> ir
"{\"fields\":[1,2],\"type\":\"Base.Complex{Core.Int64}\"}"
```


<a target='_blank' href='https://github.com/Jugsaw/Jugsaw.jl/blob/39df1bcf19f70c7211868d09cdfe98f3762e0b5e/src/jl/JugsawIR/src/ir.jl#L74' class='documenter-source'>source</a><br>

<a id='JugsawIR.native2jugsaw-Tuple{Any}' href='#JugsawIR.native2jugsaw-Tuple{Any}'>#</a>
**`JugsawIR.native2jugsaw`** &mdash; *Method*.



```julia
native2jugsaw(object)
```

Convert a native Julia object to a Jugsaw compatible object.


<a target='_blank' href='https://github.com/Jugsaw/Jugsaw.jl/blob/39df1bcf19f70c7211868d09cdfe98f3762e0b5e/src/jl/JugsawIR/src/extendedtypes.jl#L1-L5' class='documenter-source'>source</a><br>

<a id='JugsawIR.Call' href='#JugsawIR.Call'>#</a>
**`JugsawIR.Call`** &mdash; *Type*.



```julia
struct Call
```

**Fields**

  * `fname::Any`
  * `args::Tuple`
  * `kwargs::NamedTuple`


<a target='_blank' href='https://github.com/Jugsaw/Jugsaw.jl/blob/39df1bcf19f70c7211868d09cdfe98f3762e0b5e/src/jl/JugsawIR/src/Core.jl#L63' class='documenter-source'>source</a><br>

<a id='JugsawIR.JArray' href='#JugsawIR.JArray'>#</a>
**`JugsawIR.JArray`** &mdash; *Type*.



```julia
struct JArray{T}
```

The data type for arrays in Jugsaw.

**Fields**

  * `size::Vector{Int64}`
  * `storage::Vector`


<a target='_blank' href='https://github.com/Jugsaw/Jugsaw.jl/blob/39df1bcf19f70c7211868d09cdfe98f3762e0b5e/src/jl/JugsawIR/src/extendedtypes.jl#L68' class='documenter-source'>source</a><br>

<a id='JugsawIR.JDataType' href='#JugsawIR.JDataType'>#</a>
**`JugsawIR.JDataType`** &mdash; *Type*.



```julia
struct JDataType
```

The type for specifying data type in Jugsaw.

**Fields**

  * `name::String`
  * `fieldnames::Vector{String}`
  * `fieldtypes::Vector{String}`


<a target='_blank' href='https://github.com/Jugsaw/Jugsaw.jl/blob/39df1bcf19f70c7211868d09cdfe98f3762e0b5e/src/jl/JugsawIR/src/extendedtypes.jl#L82' class='documenter-source'>source</a><br>

<a id='JugsawIR.JDict' href='#JugsawIR.JDict'>#</a>
**`JugsawIR.JDict`** &mdash; *Type*.



```julia
struct JDict{K, V}
```

The dictionary type in Jugsaw, which represents a dictionary in key-value pairs.

**Fields**

  * `pairs::Array{Pair{K, V}, 1} where {K, V}`


<a target='_blank' href='https://github.com/Jugsaw/Jugsaw.jl/blob/39df1bcf19f70c7211868d09cdfe98f3762e0b5e/src/jl/JugsawIR/src/extendedtypes.jl#L20' class='documenter-source'>source</a><br>

<a id='JugsawIR.JEnum' href='#JugsawIR.JEnum'>#</a>
**`JugsawIR.JEnum`** &mdash; *Type*.



```julia
struct JEnum
```

The enum type in Jugsaw.

**Fields**

  * `kind::String`
  * `value::String`
  * `options::Vector{String}`


<a target='_blank' href='https://github.com/Jugsaw/Jugsaw.jl/blob/39df1bcf19f70c7211868d09cdfe98f3762e0b5e/src/jl/JugsawIR/src/extendedtypes.jl#L42' class='documenter-source'>source</a><br>

<a id='JugsawIR.JugsawADT' href='#JugsawIR.JugsawADT'>#</a>
**`JugsawIR.JugsawADT`** &mdash; *Type*.



```julia
struct JugsawADT
```

```
JugsawObject(typename::String, fields::Vector)
JugsawVector(vector::Vector)
```

**Fields**

  * `head::Symbol`
  * `typename::String`
  * `fields::Vector`

`JugsawADT` is an intermediate representation between Jugsaw IR data type and Julia native data type.

**Examples**

The Jugsaw object representation for `2+3im` is

```julia-repl
julia> JugsawObject("Base.ComplexF64", [2, 3])
JugsawADT(:Object, "Base.ComplexF64", [2, 3])

julia> JugsawVector([2, 3])
JugsawADT(:Vector, "", [2, 3])
```


<a target='_blank' href='https://github.com/Jugsaw/Jugsaw.jl/blob/39df1bcf19f70c7211868d09cdfe98f3762e0b5e/src/jl/JugsawIR/src/Core.jl#L133' class='documenter-source'>source</a><br>

<a id='JugsawIR.TypeTable' href='#JugsawIR.TypeTable'>#</a>
**`JugsawIR.TypeTable`** &mdash; *Type*.



```julia
struct TypeTable
```

The type definitions.

**Fields**

  * `names::Vector{String}`
  * `defs::Dict{String, JDataType}`

The `defs` defines a mapping from the type name to a [`JDataType`](JugsawIR.md#JugsawIR.JDataType) instance.


<a target='_blank' href='https://github.com/Jugsaw/Jugsaw.jl/blob/39df1bcf19f70c7211868d09cdfe98f3762e0b5e/src/jl/JugsawIR/src/adt.jl#L6' class='documenter-source'>source</a><br>


!!! warning "Missing docstring."
    Missing docstring for `native2jugsaw`. Check Documenter's build log for details.



!!! warning "Missing docstring."
    Missing docstring for `construct_object`. Check Documenter's build log for details.


