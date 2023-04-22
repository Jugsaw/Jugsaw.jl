"""
Jugsaw Universe of types!
"""
module Universe

export Graph, Base64Array
export MultiChoice, Code, Color, Dataframe, File, RGBImage
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


################ Gradio Components ###############
# Ref: https://gradio.app/docs/
# NOTE:
# 1. plots should be rendered better, supporting HTML printing, for example, rather than using Gradio builtins.

# AnnotatedImage (x)

# Audio

# BarPlot (x)

# Button (x)

# Chatbot (x)

# Checkbox -> Bool

# CheckboxGroup -> MultiChoice
struct MultiChoice{T<:Enum}
    value::Vector{T}
end

# Code
struct Code
    language::String
    value::String
end

# ColorPicker -> Color
struct Color
    value::String
    function Color(value)
        # check color
        if match(r"^#[A-F0-9]{6}$", value) !== nothing
            new(value)
        else
            throw(ArgumentError("Input must be a (capitalized) hex code string like \"#AAF597\", got $(repr(value))"))
        end
    end
end

# Dataframe
struct Dataframe{T<:Tuple}
    headers::Vector{String}
    value::Vector{T}
    function Dataframe(headers::Vector{String}, value::Vector{T}) where T
        @assert length(headers) == length(T.parameters) "header length should be consistent with the tuple size. Got $(length(headers)) and $(length(T.parameters))."
        new{T}(headers, value)
    end
end

# Dataset (x)

# Dropdown -> Enum

# File
struct File
    filename::String
    value::Vector{UInt8}
end

# Gallery

# HTML -> Base.HTML

# HighlightedText (x)

# Image
struct RGBImage
    value::Array{Float64,3}
    function RGBImage(value::Array{Float64,3})
        @assert size(value, 1) == 3 "The first dimension of an RGB image must be 3."
        new(value)
    end
end

# Interpretation (x)

# JSON (x)

# Label (x)

# LinePlot (x)

# Markdown (x)

# Model3D

# Number -> Int64, Float64

# Plot (x)

# Radio -> Choice (dup)

# ScatterPlot (x)

# Slider -> Float64 (dup)

# State (x)

# Textbox -> String

# Timeseries

# UploadButton (dup)

# Video

# -------------------------
# Implement == for data types containing vectors
for T in [:MultiChoice, :Dataframe, :File, :RGBImage]
    @eval function Base.:(==)(a::$T, b::$T)
        return all(f->getfield(a, f) == getfield(b, f), fieldnames($T))
    end
end

end