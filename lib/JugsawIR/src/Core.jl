#                      string, number, integer, boolean, null.
const JSONTypes = Union{String, Float64, Int64, Bool, Nothing}
# NOTE: object and array are not listed

# types that can be directly represented as JSONTypes.
const DirectlyRepresentableTypes = Union{
    JSONTypes, Char,
    Int8, Int16, Int32, Int128,
    UInt8, UInt16, UInt32, UInt64, UInt128,
    Float16, Float32,
    Nothing, Symbol, Missing
}

# the string representation of basic types
function type2str(::Type{T}) where T
    if T === Any   # the only abstract type
        return "Core.Any"
    elseif !isconcretetype(T)
        if T isa DataType
            typename = "$(modname(T)).$(string(T))"
        elseif T isa UnionAll
            typename = "$(modname(T)).$(string(T))"
        elseif T isa Union
            typename = string(T)
        else
            @warn "type category unknown: $T"
            typename = string(T)
        end
    elseif length(T.parameters) > 0 || T === Tuple{}
        typename = "$(modname(T)).$(_nosharp(T.name.name)){$(join([p isa Type ? type2str(p) : repr(p) for p in T.parameters], ", "))}"
    else
        typename = "$(modname(T)).$(_nosharp(T.name.name))"
    end
    return typename
end
# remove `#` from the function name to avoid parsing error
function _nosharp(s::Symbol)
    s = strip(String(s), '#')
    return first(split(s, "#"))
end
function modname(T::DataType)
    mod = T.name.module
    return string(mod)
end
function modname(T::UnionAll)
    return modname(T.body)
end

# string as type and type to string
function str2type(m::Module, str::String)
    ex = Meta.parse(str)
    @match ex begin
        :($mod.$name{$(paras...)}) || :($mod.$name) ||
            ::Symbol || :($name{$(paras...)}) => Core.eval(m, ex)
        _ => Any
    end
end

value_type(::AbstractDict{T, V}) where {T,V} = V
key_type(::AbstractDict{T}) where {T} = T

################### Types ####################
"""
$(TYPEDEF)

### Fields
$(TYPEDFIELDS)
"""
struct Call
    fname
    args::Tuple
    kwargs::NamedTuple
end
Base.:(==)(a::Call, b::Call) = a.fname == b.fname && a.args == b.args && a.kwargs == b.kwargs

feval(f::Call, args...; kwargs...) = f.fname(args...; kwargs...)
# evaluate nested function call
fevalself(x) = x
fevalself(f::Call) = feval(f, map(fevalself, f.args)...; update_kwargs(f.kwargs, map(fevalself, f.kwargs))...)
update_kwargs(::NamedTuple{K, V}, vals) where {K, V} = length(K) == 0 ? (;) : NamedTuple{K}((vals...,))

function Base.show(io::IO, f::Call)
    kwargs = join(["$k=$(repr(v))" for (k, v) in pairs(f.kwargs)], ", ")
    args = join([repr(v) for v in f.args], ", ")
    print(io, "$(f.fname)($args; $kwargs)")
end
Base.show(io::IO, ::MIME"text/plain", f::Call) = Base.show(io, f)

##### Storage is a special type that will be parsed directly
struct Storage{T} <: AbstractVector{T}
    storage::Vector{T}
end
Base.getindex(s::Storage, i::Int) = getindex(s.storage, i)
Base.length(s::Storage) = length(s.storage)
Base.size(s::Storage) = size(s.storage)
Base.size(s::Storage, i::Int) = size(s.storage, i)

struct JugsawDemo
    fcall::Call
    result
    meta::Dict{String, String}
end
Base.:(==)(d1::JugsawDemo, d2::JugsawDemo) = d1.fcall == d2.fcall && d1.result == d2.result && d1.meta == d2.meta

function Base.show(io::IO, demo::JugsawDemo)
    print(io, demo.fcall)
    print(io, " == $(repr(demo.result))")
end
ftest(demo::JugsawDemo) = fevalself(demo.fcall) == demo.result

# create a (simplest) demo instance for a certain type
demoof(::Type{T}) where T<:Number = zero(T)
demoof(::Type{T}) where T<:AbstractString = T("")
demoof(::Type{T}) where T<:Symbol = :x
demoof(::Type{T}) where T<:DataType = Float64
demoof(::Type{T}) where T<:Tuple = (demoof.(T.parameters)...,)
demoof(::Type{T}) where {E,N,T<:AbstractArray{E,N}} = T(reshape([demoof(E)], ones(Int, N)...))
function demoof(::Type{T}) where T
    vals = demoof.(T.types)
    return Core.eval(@__MODULE__, Expr(:new, T, Any[:($vals[$i]) for i=1:length(vals)]...))
end
function demoofelement(demo::Array{T}) where T
    if isabstracttype(T)
        throw(TypeTooAbstract(demo))
    end
    return length(demo) > 0 ? first(demo) : demoof(eltype(demo))
end
function demoofelement(demo::Dict{K,V}) where {K, V}
    if isabstracttype(K) || isabstracttype(V)
        throw(TypeTooAbstract(demo))
    end
    return length(demo) > 0 ? first(demo) : (demoof(K) => demoof(V))
end

############ ADT
"""
$TYPEDEF

### Fields
$TYPEDFIELDS

`JugsawExpr` is an intermediate representation between Jugsaw IR data type and Julia native data type.
The head can be one of [:object, :untyped, :list, :call]

### Examples
The Jugsaw object representation for `2+3im` is
```jldoctest; setup=:(using JugsawIR)
julia> JugsawExpr(:object, Any["Base.ComplexF64", 2, 3])
JugsawExpr(:object, ["Base.ComplexF64", 2, 3])

julia> JugsawExpr(:list, [2, 3])
JugsawExpr(:list, [2, 3])
```
"""
struct JugsawExpr
    head::Symbol
    args::Vector{Any}
    function JugsawExpr(head::Symbol, args::AbstractVector)
        if head ∉ (:object, :untyped, :list, :call)
            error("unknown expression head: $head")
        end
        return new(head, args)
    end
end
Base.:(==)(a::JugsawExpr, b::JugsawExpr) = all(fn->getfield(a, fn) == getfield(b, fn), fieldnames(JugsawExpr))
Base.show(io::IO, ::MIME"text/plain", ex::JugsawExpr) = Base.show(io, ex)
function Base.show(io::IO, ex::JugsawExpr)
    if ex.head == :object
        typename, fields... = ex.args
        print(io, "$typename(")
        print_args(io, fields)
        print(io, ")")
    elseif ex.head == :untyped
        print(io, "(")
        print_args(io, ex.args)
        print(io, ")")
    elseif ex.head == :call
        fname, args, kwargs = ex.args
        print(io, "$(fname)(")
        print_args(io, args)
        print(io, "; ")
        print_args(io, kwargs)
        print(io, ")")
    elseif ex.head == :list
        print(io, ex.args)
    else
        print(io, ex)
    end
end
function print_args(io, args, deliminator=", ")
    for (k, arg) in enumerate(args)
        print(io, arg)
        k != length(args) && print(io, deliminator)
    end
end

function unpack_object(expr::JugsawExpr)
    @assert expr.head == :object || expr.head == :untyped
    if expr.head == :object
        typename, fields... = expr.args
        return typename, fields
    else
        return "", expr.args
    end
end
function unpack_fields(expr::JugsawExpr)
    @assert expr.head == :object || expr.head == :untyped
    if expr.head == :object
        return expr.args[2:end]
    else
        return expr.args
    end
end
function unpack_typename(expr::JugsawExpr)
    @assert expr.head == :object
    return expr.args[1]
end

function unpack_list(expr::JugsawExpr)
    @assert expr.head == :list
    return expr.args
end

function unpack_call(expr::JugsawExpr)
    @assert expr.head == :call
    return expr.args
end