module JugsawIR
# BASIC types: nothing, primitive types, Complex{P},
#              Graph, SparseMatrixCSC{Ti,Tv}, Vector{T}, Tuple{T...},
#              Tensor{T}
import JSON
using MLStyle: @active, @match
export json4, parse4, jsontype4

include("Core.jl")
include("deserialize.jl")
include("serialize.jl")

end
