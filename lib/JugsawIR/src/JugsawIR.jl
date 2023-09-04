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
include("typetable.jl")
include("testkit.jl")
include("typeext.jl")

end