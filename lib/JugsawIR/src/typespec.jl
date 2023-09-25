"""
$TYPEDEF

The type for specifying data type in Jugsaw.

### Fields
$TYPEDFIELDS

- `name` is the name of the type,
- `structtype` is the type of the JSON3 struct. Please check https://quinnj.github.io/JSON3.jl/dev/#DataTypes
- `fieldtypes` is the type of the fields. It is a vector of `TypeSpec` instances.
For Array structtype, it is a single element vector of `TypeSpec` instances of the element type.
"""
struct TypeSpec
    name::String
    structtype::String
    description::String

    # for struct types
    fieldnames::Vector{String}
    fieldtypes::Vector{TypeSpec}
    fielddescriptions::Vector{String}
end
function TypeSpec(::Type{T}; fielddescriptions=nothing) where T
    structtype = String(typeof(JSON3.StructTypes.StructType(T)).name.name)
    # field names and fields
    if structtype == "NumberType"
        fieldnames = String[]
        fts = TypeSpec[]
    elseif structtype == "StringType"
        fieldnames = String[]
        fts = TypeSpec[]
    elseif structtype == "BoolType"
        fieldnames = String[]
        fts = TypeSpec[]
    elseif structtype == "NullType"
        fieldnames = String[]
        fts = TypeSpec[]
    elseif structtype == "DictType"
        if T <: NamedTuple
            fieldnames = String[String(x) for x in fieldnames(T)]
            fts = TypeSpec[TypeSpec(x) for x in fieldtypes(T)]
        else
            fieldnames = String[]
            fts = TypeSpec[TypeSpec(et) for et in T.parameters]
        end
    elseif structtype == "CustomStruct"
        return TypeSpec(JSON3.StructTypes.lowertype(T))
    elseif structtype == "UnorderedStruct"
        if isabstracttype(T)
            fieldnames, fts = String[], TypeSpec[]
        else
            fieldnames = String[String(fn) for fn in Base.fieldnames(T)]
            fts = TypeSpec[TypeSpec(x) for x in fieldtypes(T)]
        end
    elseif structtype == "ArrayType"
        fieldnames = String[]
        if T <: Tuple
            fts = TypeSpec[TypeSpec(x) for x in T.parameters]
        else
            fts = TypeSpec[TypeSpec(eltype(T))]
        end
    else
        error("`$T` of StructType: `$structtype` not supported yet!!!!")
    end
    name = type2str(T)
    desc = description(T)
    fdesc = fielddescriptions === nothing ? fill("", length(fieldnames)) : fielddescriptions
    return TypeSpec(name, structtype, desc, fieldnames, fts, fdesc)
end

####################
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
        typename = "$(modname(T)).$(_nosharp(T.name.name)){$(join([p isa Type ? type2str(p) : repr(p) for p in T.parameters], ", "))}"
    else
        typename = "$(modname(T)).$(_nosharp(T.name.name))"
    end
    return typename
end
# remove `#` from the function name to avoid parsing error
function _nosharp(s::Symbol)
    s = strip(String(s), '#')
    return first(split(s, "#"))
end
function modname(T::DataType)
    mod = T.name.module
    return string(mod)
end
function modname(T::UnionAll)
    return modname(T.body)
end