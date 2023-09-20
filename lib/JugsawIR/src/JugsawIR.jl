module JugsawIR
# BASIC types: nothing, primitive types, Complex{P},
#              Graph, SparseMatrixCSC{Ti,Tv}, Vector{T}, Tuple{T...},
#              Tensor{T}
import JSON3
using MLStyle: @active, @match
import MLStyle
using AbstractTrees
using AbstractTrees: print_tree
using DocStringExtensions

export TypeTable
export Call, feval, fevalself
export JugsawDemo, ftest
export TypeTooAbstract
export TypeSpec
export SizedArray

include("Core.jl")
include("errors.jl")
include("typespec.jl")
include("testkit.jl")
include("typeext.jl")

function read_object(obj)
    return JSON3.read(obj)
end
function read_object(obj, ::Type{T}) where T
    return JSON3.read(obj, T)
end
function read_object(obj, demo)
    return read_object(obj, typeof(demo))
end

function write_object(io::IO, obj)
    return JSON3.write(io, obj)
end
function write_object(obj)
    return JSON3.write(obj)
end

end