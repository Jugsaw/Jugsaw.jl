#!!! design choice: function name space is local, type name space is global.
#!!! design choice: abstract type information are lost during conversion!
#!!! TODO: protect the names of existing types.
#!!! TODO: function name and app name check.
# NOTE: undef is so hard to support.
###### Array element types that can be compressed with base64 encoding.
const ArrayPrimitiveTypes = Union{Bool, Char,
    Int8, Int16, Int32, Int64, Int128,
    UInt8, UInt16, UInt32, UInt64, UInt128,
    Float16, Float32, Float64,
    ComplexF16, ComplexF32, ComplexF64, Complex{Int16}, Complex{Int32}, Complex{Int64}, Complex{Int128}}

###### Data types that can be used without definition
# note: function is not allowed, only JugsawFunction is allowed.
# TODO: add array types
const BasicTypes = Union{ArrayPrimitiveTypes, DataType, Any, Symbol, String, UndefInitializer, Nothing}

# the string representation of basic types
type_strings!(res, type::Union) = (push!(res, type2str(type.a)); type_strings!(res, type.b))
type_strings!(res, type::DataType) = (push!(res, type2str(type)); res)
function type2str(::Type{T}) where T
    if T === Any   # the only abstract type
        return "Any"
    elseif !isconcretetype(T)
        @warn "Concrete types are expected! got $T, converting to `Any`."
        typename = "Any"
    elseif length(T.parameters) > 0 || T === Tuple{}
        typename = "$(String(T.name.name)){$(join([p isa Type ? type2str(p) : (p isa Symbol ? ":$p" : string(p)) for p in T.parameters], ", "))}"
    else
        typename = "$(String(T.name.name))"
    end
    return typename
end

# all derived types are represented with basic types, so they must include all primitive types in Julia
const basic_types = type_strings!(String[], BasicTypes)

###################### types in Jugsaw stdlib ##########################
"""
    Graph

The data type for representing a graph.

### Fields
* `nv::Int` is the number of vertices. The vertices are `{1, 2, ..., nv}`.
* `edges::Matrix{Int}` is a 2 x n matrix, each column is an edge.
"""
struct Graph
    nv::Int
    edges::Matrix{Int}
    function Graph(nv::Int, edges::Matrix{Int})
        @assert size(edges, 1) == 2 "The first dimension of the input edge-Matrix must be 2."
        @assert all(x->0<x<=nv, edges) "The vertex indices must be in range [1, $(nv)], got: $edges"
        new(nv, edges)
    end
end
Base.:(==)(g1::Graph, g2::Graph) = g1.nv == g2.nv && g1.edges == g2.edges

# Jugsaw function call app.fname(args, kwargs)
struct JugsawFunctionCall{argsT<:Tuple, kwargsT<:NamedTuple}
    app::String
    fname::String
    args::argsT
    kwargs::kwargsT
end
function run(mod::Module, fc::JugsawFunctionCall)
    Base.eval(mod, :($(Symbol(fc.fname))($(fc.args...); $(fc.kwargs)...)))
end

# Jugsaw function specification
struct JugsawFunctionSpec{argsT, kwargsT, retT}
    app::String
    fname::String
end
function Base.:(==)(a::JugsawFunctionSpec{argsT1, kwargsT1}, b::JugsawFunctionSpec{argsT2, kwargsT2}) where {argsT1, kwargsT1, argsT2, kwargsT2}
    return a.app == b.app && a.fname == b.fname && argsT1 === argsT2 && kwargsT1 === kwargsT2
end

function Base.show(io::IO, f::JugsawFunctionCall)
    #kwargs = join(["$k=$v" for (k, v) in zip(keys(f.kwargs), f.kwargs)], ", ")
    kwargs = []
    args = join(["$v" for v in f.args], ", ")
    print(io, "$(f.app).$(f.fname)($args; $kwargs)")
end
Base.show(io::IO, ::MIME"text/plain", f::JugsawFunctionCall) = Base.show(io, f)

function Base.show(io::IO, f::JugsawFunctionSpec{argsT, kwargsT, retT}) where {argsT, names, TT, kwargsT<:NamedTuple{names, TT}, retT}
    kwargs = join(["$k::$T" for (k, T) in zip(names, TT.parameters)], ", ")
    args = join(["::$T" for T in argsT.parameters], ", ")
    print(io, "$(f.app).$(f.fname)($args; $kwargs)::$retT")
end
Base.show(io::IO, ::MIME"text/plain", f::JugsawFunctionSpec) = Base.show(io, f)