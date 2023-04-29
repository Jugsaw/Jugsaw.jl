#!!! design choice: function name space is local, type name space is global.
#!!! design choice: abstract type information are lost during conversion!
#!!! TODO: protect the names of existing types.
#!!! TODO: function name and app name check.
# NOTE: undef is so hard to support.
###### Array element types that can be compressed with base64 encoding.
###### Data types that can be used without definition
# note: function is not allowed, only JugsawFunction is allowed.
# TODO: add array types

#                      string, number, integer, boolean, null.
const JSONTypes = Union{String, Float64, Int64, Bool, Nothing}
# object and array are not listed

const BasicTypes = Union{
    Bool, Char,
    Int8, Int16, Int32, Int64, Int128,
    UInt8, UInt16, UInt32, UInt64, UInt128,
    Float16, Float32, Float64,
    DataType, Symbol, String, UndefInitializer, Nothing, Missing
}

# the string representation of basic types
type_strings!(res, type::Union) = (push!(res, type2str(type.a)); type_strings!(res, type.b))
type_strings!(res, type::DataType) = (push!(res, type2str(type)); res)
function type2str(::Type{T}) where T
    if T === Any   # the only abstract type
        return "Core.Any"
    elseif !isconcretetype(T)
        @warn "Concrete types are expected! got $T."
        if T isa DataType
            typename = "$(modname(T)).$(string(T))"
        elseif T isa UnionAll
            typename = "$(modname(T)).$(string(T))"
        elseif T isa Union
            typename = string(T)
        else
            @warn "type category unknown: $T"
            typename = string(T)
        end
    elseif length(T.parameters) > 0 || T === Tuple{}
        typename = "$(modname(T)).$(String(T.name.name)){$(join([p isa Type ? type2str(p) : (p isa Symbol ? ":$p" : string(p)) for p in T.parameters], ", "))}"
    else
        typename = "$(modname(T)).$(String(T.name.name))"
    end
    return typename
end

# string as type and type to string
function str2type(m::Module, str::String)
    ex = Meta.parse(str)
    @match ex begin
        :($mod.$name{$(paras...)}) || :($mod.$name) ||
            ::Symbol || :($name{$(paras...)}) => Core.eval(m, ex)
        _ => Any
    end
end

function modname(T::DataType)
    mod = T.name.module
    return string(mod)
end
function modname(T::UnionAll)
    return modname(T.body)
end

@active IsBasicType(x) begin
    x <: BasicTypes
end
@active IsConcreteType(x) begin
    isconcretetype(x)
end

value_type(::Type{<:AbstractDict{T, V}}) where {T,V} = V
key_type(::Type{<:AbstractDict{T}}) where {T} = T

