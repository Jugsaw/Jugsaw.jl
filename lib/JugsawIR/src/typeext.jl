# parse sized array
struct SizedArray{T, N}
    data::Vector{T}
    size::NTuple{N, Int}
end
SizedArray(arr::AbstractArray) = SizedArray(vec(arr), size(arr))
JSON3.StructTypes.StructType(::Type{SizedArray{T, N}}) where {T, N} = JSON3.StructTypes.Struct()

# parse complex number
JSON3.StructTypes.StructType(::Type{Complex{T}}) where T = JSON3.StructTypes.Struct()