module JugsawIR
# BASIC types: nothing, primitive types, Complex{P},
#              Graph, SparseMatrixCSC{Ti,Tv}, Vector{T}, Tuple{T...},
#              Tensor{T}
import JSON
import JSON.Writer
import JSON.Writer.JSONContext
import Base64: base64encode, base64decode
export @parsetype

###### Data types
const ArrayPrimitiveTypes = Union{Bool, Char,
    Int8, Int16, Int32, Int64, Int128,
    UInt8, UInt16, UInt32, UInt64, UInt128,
    Float16, Float32, Float64,
    ComplexF16, ComplexF32, ComplexF64, Complex{Int16}, Complex{Int32}, Complex{Int64}, Complex{Int128}}

include("stdtypes.jl")
include("deserialize.jl")
include("serialize.jl")

end
