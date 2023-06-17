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
using DocStringExtensions

export julia2ir, ir2julia, TypeTable, JugsawADT
export Call, feval, fevalself
export JugsawDemo, ftest
export TypeTooAbstract
export JArray, JDataType, JDict, JEnum

const jp = Lark(read(joinpath(@__DIR__, "jugsawir.lark"), String),parser="lalr",lexer="contextual", start="object")

include("Core.jl")
include("errors.jl")
include("extendedtypes.jl")
include("adt.jl")
include("ir.jl")
include("testkit.jl")

end