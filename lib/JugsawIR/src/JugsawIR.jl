module JugsawIR

import JSON3
using DocStringExtensions
using Base64

# Call and Demo
export Call, feval, fevalself
export JugsawDemo, ftest
# Errors
export TypeTooAbstract
# Describing a type
export TypeSpec
# Extended types
export SizedArray, Graph, Base64Array
# Interfaces for read/write object
export description, read_object, write_object

include("Core.jl")
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