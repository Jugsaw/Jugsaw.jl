module JugsawIR
# BASIC types: nothing, primitive types, Complex{P},
#              Graph, SparseMatrixCSC{Ti,Tv}, Vector{T}, Tuple{T...},
#              Tensor{T}
import JSON
using MLStyle: @active, @match
using Lerche
using AbstractTrees
using AbstractTrees: print_tree

export json4, parse4, jsontype4, print_tree, print_clean_tree
export JugsawFunctionCall, function_signature, feval
export ftest, JugsawDemo

include("Core.jl")
include("serialize.jl")
include("types.jl")

end
