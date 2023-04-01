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

