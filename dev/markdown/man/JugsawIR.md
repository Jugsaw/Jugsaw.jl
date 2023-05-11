


<a id='Jugsaw-IR'></a>

<a id='Jugsaw-IR-1'></a>

# Jugsaw IR


[JugsawIR](@ref) is an intermediate representation (IR) for exposing and using cloud scientific applications. Its grammar is compatible with JSON at the time of writing, however, it might undergo a refactor to support richer features. The final form should be a real programming language for Web Virtual Machine.


Jugsaw IR can represent data, data types, and function calls. The basic rule is representing a Jugsaw object as a JSON object with extra constaints,


1. Integers, floating point numbers, `Nothing`, `Missing`, `UndefInitializer`, `Symbol` and `String` are directly representable.
2. Generic objects are represented by a JSON object with at most two fields: `fields` and `type` (optional).
3. Some objects are specialized, including `Array`, `Tuple`, `Dict`, `DataType` and `Enum`.


<a id='Examples-1:-Representing-Data'></a>

<a id='Examples-1:-Representing-Data-1'></a>

## Examples 1: Representing Data


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



<a id='Examples-2:-Representing-Data-Type'></a>

<a id='Examples-2:-Representing-Data-Type-1'></a>

## Examples 2: Representing Data Type


A type is a special Jugsaw object with three fields `name`, `fieldnames` and `fieldtypes`. For example, to represent a complex number type, we can create the following IR


```julia
julia> julia2ir(ComplexF64)[1] |> println
{"fields":["Base.Complex{Core.Float64}",["re","im"],["Core.Float64","Core.Float64"]],"type":"Core.DataType"}
```


For convenience, JugsawIR returns a [`TypeTable`](@ref) instance to represent the types used in parsing.


<a id='Examples-3:-Representing-Funcation-Call'></a>

<a id='Examples-3:-Representing-Funcation-Call-1'></a>

## Examples 3: Representing Funcation Call


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
