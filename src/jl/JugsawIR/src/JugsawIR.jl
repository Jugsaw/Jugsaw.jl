module JugsawIR
# BASIC types: nothing, primitive types, Complex{P},
#              Graph, SparseMatrixCSC{Ti,Tv}, Vector{T}, Tuple{T...},
#              Tensor{T}
import JSON3
using MLStyle: @active, @match
import MLStyle
using Lerche
using AbstractTrees
using AbstractTrees: print_tree
using Expronicon
using Expronicon
using Expronicon.ADT: @adt

export julia2ir, ir2julia, print_tree, print_clean_tree, TypeTable, JugsawADT
export Call, function_signature, feval, fevalself
export ftest, JugsawDemo

include("Core.jl")
include("extendedtypes.jl")
include("adt.jl")
include("ir.jl")

end
