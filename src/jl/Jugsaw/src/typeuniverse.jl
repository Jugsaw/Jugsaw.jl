"""
Jugsaw Universe of types!
"""
module Universe

export Graph, Base64Array

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

end