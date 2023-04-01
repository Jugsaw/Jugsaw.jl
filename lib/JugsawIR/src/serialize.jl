using DataStructures: OrderedDict
# Extended JSON
# https://github.com/JuliaIO/JSON.jl
mutable struct JSON4Context <: JSONContext
    underlying::JSONContext
    extra_types::OrderedDict{String, String}
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
        ::Type{T}) where T
    sT = typedef!(io, s, T)
    JSON.show_json(io, s, sT)
end

function typedef!(io, s, ::Type{T}) where T
    sT = type2str(T)
    # avoid repeated definition of function table
    if sT ∈ basic_types || haskey(io.extra_types, sT)
        return sT
    end

    # define field types recursively
    fieldnames = String[]
    for t in T.types
        st = typedef!(io, s, t)
        push!(fieldnames, st)
    end
    buf = IOBuffer()
    jio = JSON4Context(buf)
    JSON.begin_object(jio)
    JSON.show_pair(jio, s, :__type__ => "DataType")
    JSON.show_pair(jio, s, :name => sT)
    JSON.show_pair(jio, s, :fieldtypes => fieldnames)
    JSON.end_object(jio)
    io.extra_types[sT] = String(take!(buf))
    return sT
end

# generic object
function JSON.show_json(io::JSON4Context, s::JSON.CommonSerialization, x::JSON.Writer.CompositeTypeWrapper)
    Tx = typeof(x.wrapped)
    typename = type2str(Tx)
    if typename ∉ basic_types && !haskey(io.extra_types, typename)
        typedef!(io, s, Tx)
    end

    # show this object
    JSON.begin_object(io)
    JSON.show_pair(io, s, :__type__ => typename)
    for fn in x.fns
        JSON.show_pair(io, s, fn, getproperty(x.wrapped, fn))
    end
    JSON.end_object(io)
end

function json4(obj)
    io = IOBuffer()
    cio = JSON4Context(JSON.Writer.CompactContext(io), OrderedDict{String,String}())
    JSON.show_json(cio, JSON.Serializations.StandardSerialization(), obj)
    obj = String(take!(io))
    return "[" * join([values(cio.extra_types)..., obj], ", ") * "]"
end

function parse4(str::AbstractString;
               type = Any,
               mod = @__MODULE__,
               dicttype=OrderedDict{String,Any},
               inttype::Type{<:Real}=Int64,
               allownan::Bool=true,
               null=nothing)
    parsetype(mod, type, JSON.parse(str; dicttype, inttype, allownan, null))
end