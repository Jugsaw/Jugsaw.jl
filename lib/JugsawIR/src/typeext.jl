# parse sized array
struct SizedArray{T, N}
    data::Vector{T}
    size::NTuple{N, Int}
end
SizedArray(arr::AbstractArray) = SizedArray(vec(arr), size(arr))
JSON3.StructTypes.StructType(::Type{SizedArray{T, N}}) where {T, N} = JSON3.StructTypes.Struct()

# parse complex number
JSON3.StructTypes.StructType(::Type{Complex{T}}) where T = JSON3.StructTypes.Struct()

# parse a call
JSON3.StructTypes.StructType(::Type{<:Call}) = JSON3.StructTypes.CustomStruct()
JSON3.StructTypes.lower(x::Call) = (string(x.fname), x.args, x.kwargs)
JSON3.StructTypes.lowertype(::Type{Call{FT,argsT,kwargsT}}) where {FT, argsT, kwargsT} = Tuple{String, argsT, kwargsT}
JSON3.StructTypes.construct(::Type{<:Call{FT}}, x) where FT = Call(FT.instance, x[2], x[3])

# parse a demo
JSON3.StructTypes.StructType(::Type{<:JugsawDemo}) = JSON3.StructTypes.Struct()

# pirate for NamedTuple
Base.@NamedTuple{}() = (;)