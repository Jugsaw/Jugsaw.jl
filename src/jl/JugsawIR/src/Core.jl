#                      string, number, integer, boolean, null.
const JSONTypes = Union{String, Float64, Int64, Bool, Nothing}
# NOTE: object and array are not listed

# types that can be directly represented as JSONTypes.
const DirectlyRepresentableTypes = Union{
    JSONTypes, Char,
    Int8, Int16, Int32, Int128,
    UInt8, UInt16, UInt32, UInt64, UInt128,
    Float16, Float32,
    Nothing, Symbol, Missing
}

# the string representation of basic types
function type2str(::Type{T}) where T
    if T === Any   # the only abstract type
        return "Core.Any"
    elseif !isconcretetype(T)
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
function modname(T::DataType)
    mod = T.name.module
    return string(mod)
end
function modname(T::UnionAll)
    return modname(T.body)
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

value_type(::AbstractDict{T, V}) where {T,V} = V
key_type(::AbstractDict{T}) where {T} = T

