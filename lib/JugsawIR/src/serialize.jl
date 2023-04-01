# Extended JSON
# https://github.com/JuliaIO/JSON.jl
mutable struct JSON4Context <: JSONContext
    underlying::JSONContext
    types::Vector{String}
end

for delegate in [:indent,
                 :delimit,
                 :separate,
                 :begin_array,
                 :end_array,
                 :begin_object,
                 :end_object]
    @eval JSON.Writer.$delegate(io::JSON4Context) = JSON.Writer.$delegate(io.underlying)
end
Base.write(io::JSON4Context, byte::UInt8) = write(io.underlying, byte)

# primitive array specialization
function JSON.show_json(io::JSON4Context,
    s::JSON.CommonSerialization,
    x::Array{T}) where T <: ArrayPrimitiveTypes
    JSON.begin_object(io)
    JSON.show_pair(io, s, :__type__ => type2str(typeof(x)))
    JSON.show_pair(io, s, :size => size(x))
    JSON.show_pair(io, s, :storage => base64encode(x))
    JSON.end_object(io)
end

# primitive array specialization
function JSON.show_json(io::JSON4Context,
    s::JSON.CommonSerialization,
    x::Type{T}) where T
    JSON.begin_object(io)
    JSON.show_pair(io, s, :__type__ => type2str(typeof(x)))
    JSON.show_pair(io, s, :size => size(x))
    JSON.show_pair(io, s, :storage => base64encode(x))
    JSON.end_object(io)
end

# generic object
function JSON.show_json(io::JSON4Context, s::JSON.CommonSerialization, x::JSON.Writer.CompositeTypeWrapper)
    JSON.begin_object(io)
    typename = type2str(typeof(x.wrapped))
    if !hastype(io, typename)
        typedef!(io, T, typename)
    end
    JSON.show_pair(io, s, :__type__ => typename)
    for fn in x.fns
        JSON.show_pair(io, s, fn, getproperty(x.wrapped, fn))
    end
    JSON.end_object(io)
end

function json4(obj)
    io = IOBuffer()
    cio = JSON4Context(JSON.Writer.CompactContext(io))
    JSON.show_json(cio, JSON.Serializations.StandardSerialization(), obj)
    return String(take!(io))
end

function parse4(str::AbstractString;
               type = Any,
               mod = @__MODULE__,
               dicttype=Dict{String,Any},
               inttype::Type{<:Real}=Int64,
               allownan::Bool=true,
               null=nothing)
    parsetype(mod, type, JSON.parse(str; dicttype, inttype, allownan, null))
end

function type2str(::Type{T}) where T
    if length(T.parameters) > 0
        typename = "$(String(T.name.name)){$(join([p isa Type ? type2str(p) : string(p) for p in T.parameters], ", "))}"
    else
        typename = "$(String(T.name.name))"
    end
    return typename
end