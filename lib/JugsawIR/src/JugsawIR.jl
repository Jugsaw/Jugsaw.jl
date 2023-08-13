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
using DocStringExtensions

export julia2ir, ir2julia, TypeTable, JugsawExpr
export Call, feval, fevalself
export JugsawDemo, ftest
export TypeTooAbstract
export JArray, JDataType, JDict

const jp = Lark(read(joinpath(@__DIR__, "jugsawir.lark"), String),parser="lalr",lexer="contextual", start="expr")
const jcli = Lark(read(joinpath(@__DIR__, "jugsawcli.lark"), String),parser="lalr",lexer="contextual", start="call")

include("Core.jl")
include("errors.jl")
include("extendedtypes.jl")
include("adt.jl")
include("ir.jl")
include("testkit.jl")

end