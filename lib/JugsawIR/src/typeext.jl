# parse sized array
struct SizedArray{T, N}
    data::Vector{T}
    size::NTuple{N, Int}
end
SizedArray(arr::AbstractArray) = SizedArray(vec(arr), size(arr))
JSON3.StructTypes.StructType(::Type{SizedArray{T, N}}) where {T, N} = JSON3.StructTypes.Struct()

# NOT good to autocast.
# JSON3.StructTypes.StructType(::Type{Array{T, 2}}) where {T} = JSON3.StructTypes.CustomStruct()
# JSON3.StructTypes.lower(x::Array{T, 2}) where {T} = SizedArray(x)
# JSON3.StructTypes.lowertype(::Type{Array{T, 2}}) where {T} = SizedArray{T, 2}
# JSON3.StructTypes.construct(::Type{Array{T, 2}}, x::SizedArray{T, 2}) where {T} = reshape(x.data, x.size)

# parse complex number
JSON3.StructTypes.StructType(::Type{Complex{T}}) where T = JSON3.StructTypes.Struct()