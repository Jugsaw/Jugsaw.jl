using DataStructures: OrderedDict
# Extended JSON
# https://github.com/JuliaIO/JSON.jl
# `json4` parse an object to string, which can be used to
# 1. parse a Julia object to a json object, with complete type specification.
# 2. parse a function specification to a json object, with complete input argument specification.
# `parse4` is the inverse of `json4`.
# potential issue: types with the same name in the same app may cause key conflict.
# error user if the type contains a __type__ field.

const CS = JSON.Serializations.CommonSerialization
struct Thunk{FT}
    f::FT
end
mutable struct JSON4Context <: JSONContext
    underlying::JSONContext
    extra_types::OrderedDict{DataType, String}  # from type name to type definition
end
JSON4Context(io) = JSON4Context(JSON.Writer.CompactContext(io), OrderedDict{String,String}())

for delegate in [:indent,
                 :delimit,
                 :separate,
                 :begin_array,
                 :end_array,
                 :begin_object,
                 :end_object]
    @eval JSON.Writer.$delegate(io::JSON4Context) = JSON.Writer.$delegate(io.underlying)
end
function print_object(f, io::IO)
    JSON.begin_object(io)
    f()
    JSON.end_object(io)
end
Base.write(io::JSON4Context, byte::UInt8) = write(io.underlying, byte)

function typedef!(types::AbstractDict, ::Type{T}) where T
    sT = type2str(T)
    # avoid repeated definition of function table
    if T === Any || T <: BasicTypes || haskey(types, T)
        return sT
    elseif !isconcretetype(T)
        @warn "$T is not a concrete type, parsed to `Any`"
        return "Any"
    elseif (T <: Enum)
        types[sT] = OrderedDict("__type__"=>"DataType",
                        "name"=>sT,
                        "instances"=>string.(instances(T))
                )
        return sT
    end

    # define parameter types
    for t in T.parameters
        if t isa Type
            typedef!(types, t)
        end
    end
    # define field types recursively
    d = OrderedDict{String, String}()
    for (n, t) in zip(fieldnames(T), T.types)
        d[string(n)] = typedef!(types, t)
    end

    # show self
    types[sT] = OrderedDict("__type__"=>"DataType",
                "name" => sT,
                "fields" => d
            )
    return sT
end

# if an fallback happens, a ambiguity error will be throwed.
function JSON.show_json(io::JSON4Context, s::CS, x)
    if isprimitivetype(x)
        error("we do not accept fallback!")
    else
        show_composite(io, s, x)
    end
end
# type specification
function JSON.show_json(io::JSON4Context, s::CS, ::Type{T}) where T
    JSON.show_json(io, s, type2str(T))
end
# generic object
function show_composite(io::JSON4Context, s::CS, x::Tx) where Tx
    typename = type2str(Tx)
    # show this object
    JSON.begin_object(io)
    JSON.show_pair(io, s, "__type__", typename)
    for fn in fieldnames(Tx)
        if isdefined(x, fn)
            JSON.show_pair(io, s, fn, getfield(x, fn))
        else
            JSON.show_pair(io, s, fn, undef)
        end
    end
    JSON.end_object(io)
end

function json4(obj)
    io = IOBuffer()
    cio = JSON4Context(JSON.Writer.CompactContext(io), OrderedDict{String,String}())
    s = JSON.Serializations.StandardSerialization()
    JSON.show_json(cio, s, obj)
    return String(take!(io))
end

function jsontype4(::Type{T}) where T
    types = OrderedDict{String, OrderedDict{String, Any}}()
    typedef!(types, T)
    return JSON.json(types)
end

######################## Specialization #############################
# for objects that can not be easily parsed with generic object parsing rules.
function dump_object(io, s, d::Pair...)
    JSON.begin_object(io)
    for (k, v) in d
        JSON.show_pair(io, s, k, v)
    end
    JSON.end_object(io)
end
function dump_object(io, s, d::AbstractDict)
    JSON.begin_object(io)
    for (k, v) in d
        JSON.show_pair(io, s, k, v)
    end
    JSON.end_object(io)
end
function JSON.show_json(io::JSON4Context, s::CS, x::Array{T}) where T
    dump_object(io, s,
        "__type__"=> type2str(typeof(x)),
        "size" => collect(Int, size(x)),
        "content"=> vec(x)
    )
end
function JSON.show_json(io::JSON4Context, s::CS, x::Vector{T}) where T
    invoke(JSON.show_json, Tuple{JSONContext, CS, Vector{T}}, io, s, x)
end

# overwrite the methods already defined in JSON,
# dict
function JSON.show_json(io::JSON4Context, s::CS, x::Union{OrderedDict{T1,T2}, Dict{T1, T2}}) where {T1, T2}
    dump_object(io, s, "__type__"=>type2str(typeof(x)), "data" =>Thunk(()->dump_object(io, s, x)))
end
function JSON.show_json(io::JSON4Context, s::CS, t::Thunk)
    t.f()
end

# overwrite the methods already defined in JSON,
function JSON.show_json(io::JSON4Context, s::CS, x::T) where T<:Union{AbstractFloat, Integer}
    if T <: BasicTypes   # the default behavior
        if isfinite(x)
            Base.print(io, x)
        else
            JSON.show_null(io)
        end
    elseif !isprimitivetype(T)    # we do not accept fallbacks!
        return show_composition(io, s, x)
    else
        error("the number type is neither a composite type, nor a basic type.")
    end
end

for T in [:Pair, :NamedTuple, :AbstractVector, :AbstractArray, :AbstractDict, :(JSON.Writer.Dates.TimeType)]
    @eval function JSON.show_json(io::JSON4Context, s::CS, x::$T)
        show_composite(io, s, x)
    end
end
function JSON.show_json(io::JSON4Context, s::CS, x::Tuple)
    dump_object(io, s, "__type__"=>type2str(typeof(x)), ["$name" => getfield(x, name) for name in fieldnames(typeof(x))]...)
end
for T in [:Char, :String, :Symbol, :Enum]
    @eval function JSON.show_json(io::JSON4Context, s::CS, x::$T)
        invoke(JSON.show_json, Tuple{JSONContext, CS, $T}, io, s, x)
    end
end