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
JSON3.StructTypes.lower(x::Call) = (; fname=string(x.fname), args=x.args, kwargs=x.kwargs)
JSON3.StructTypes.lowertype(::Type{Call{FT,argsT,kwargsT}}) where {FT, argsT, kwargsT} = NamedTuple{(:fname, :args, :kwargs), Tuple{String, argsT, kwargsT}}
JSON3.StructTypes.construct(::Type{<:Call{FT}}, x) where FT = Call(FT.instance, x.args, x.kwargs)

# parse a demo
JSON3.StructTypes.StructType(::Type{<:JugsawDemo}) = JSON3.StructTypes.Struct()

# pirate for NamedTuple
Base.@NamedTuple{}() = (;)


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
    function Graph(nv::Int)
        new(nv, zeros(Int, 2, 0))
    end
end
Base.:(==)(g1::Graph, g2::Graph) = g1.nv == g2.nv && g1.edges == g2.edges
JSON3.StructTypes.StructType(::Type{Graph}) = JSON3.StructTypes.CustomStruct()
JSON3.StructTypes.lower(x::Graph) = (x.nv, vec(x.edges))
JSON3.StructTypes.lowertype(::Type{Graph}) = Tuple{Int, Vector{Int}}
JSON3.StructTypes.construct(::Type{Graph}, x) = Graph(x[1], reshape(x[2], 2, :))

struct Base64Array{T}
    size::Vector{Int}
    storage::String
end
function Base64Array(a::AbstractArray{T}) where T
    if !isbitstype(T)
        error("only bits types can use base64 encoding")
    end
    Base64Array{T}(collect(Int, size(a)), base64encode(a))
end
Base.Array(base::Base64Array{T}) where T = reshape(collect(reinterpret(T, base64decode(base.storage))), base.size...)