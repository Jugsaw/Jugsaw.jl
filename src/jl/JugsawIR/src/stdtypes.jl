#!!! design choice: function name space is local, type name space is global.
#!!! design choice: abstract type information are lost during conversion!
#!!! TODO: protect the names of existing types.
#!!! TODO: function name and app name check.
# NOTE: undef is so hard to support.
###### Array element types that can be compressed with base64 encoding.
const ArrayPrimitiveTypes = Union{Bool, Char,
    Int8, Int16, Int32, Int64, Int128,
    UInt8, UInt16, UInt32, UInt64, UInt128,
    Float16, Float32, Float64,
    ComplexF16, ComplexF32, ComplexF64, Complex{Int16}, Complex{Int32}, Complex{Int64}, Complex{Int128}}

###### Data types that can be used without definition
# note: function is not allowed, only JugsawFunction is allowed.
# TODO: add array types
const BasicTypes = Union{ArrayPrimitiveTypes, DataType, Symbol, String, UndefInitializer, Nothing}

# the string representation of basic types
type_strings!(res, type::Union) = (push!(res, type2str(type.a)); type_strings!(res, type.b))
type_strings!(res, type::DataType) = (push!(res, type2str(type)); res)
function type2str(::Type{T}) where T
    if T === Any   # the only abstract type
        return "Any"
    elseif !isconcretetype(T)
        @warn "Concrete types are expected! got $T."
        typename = string(T)
    elseif length(T.parameters) > 0 || T === Tuple{}
        typename = "$(String(T.name.name)){$(join([p isa Type ? type2str(p) : (p isa Symbol ? ":$p" : string(p)) for p in T.parameters], ", "))}"
    else
        typename = "$(String(T.name.name))"
    end
    return typename
end

# all derived types are represented with basic types, so they must include all primitive types in Julia
const basic_types = type_strings!(String[], BasicTypes)