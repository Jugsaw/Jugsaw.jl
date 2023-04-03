module JugsawIR
# BASIC types: nothing, primitive types, Complex{P},
#              Graph, SparseMatrixCSC{Ti,Tv}, Vector{T}, Tuple{T...},
#              Tensor{T}
import JSON
import JSON.Writer
import JSON.Writer.JSONContext
import Base64: base64encode, base64decode
export @parsetype
export json4, parse4, jsontype4

include("stdtypes.jl")
include("deserialize.jl")
include("serialize.jl")

end
