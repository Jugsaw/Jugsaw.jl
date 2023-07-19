"""
    native2jugsaw(object)

Convert a native Julia object to a Jugsaw compatible object.
"""
native2jugsaw(x) = x

"""
    jugsaw2native(jugsaw_object, demo_object)

Reconstruct the native Julia object from an plain Jugsaw object.
The return value must have the same data type as the second argument.
"""
jugsaw2native(x, demo) = x

##### Dict
"""
$TYPEDEF

The dictionary type in Jugsaw, which represents a dictionary in key-value pairs.

### Fields
$TYPEDFIELDS
"""
struct JDict{K, V}
    pairs::Storage{Pair{K, V}}
end

function native2jugsaw(x::Dict)
    JDict(Storage(collect(x)))
end
function jugsaw2native(t::JDict, demo::AbstractDict{T, V}) where {T, V}
    return typeof(demo)(t.pairs)
end

##### Enum
"""
$TYPEDEF

The enum type in Jugsaw.

### Fields
$TYPEDFIELDS
"""
struct JEnum
    kind::String
    value::String
    options::Storage{String}
end
function native2jugsaw(x::Enum)
    JEnum(type2str(typeof(x)), string(x), Storage(String[string(v) for v in instances(typeof(x))]))
end
function jugsaw2native(t::JEnum, demo::Enum)
    typeof(demo)(findfirst(==(t.value), t.options)-1)
end
function jugsaw2native(value::String, demo::Enum)
    idx = findfirst(x->string(x)==(value), instances(typeof(demo)))
    typeof(demo)(idx-1)
end

##### Array
"""
$TYPEDEF

The data type for arrays in Jugsaw.

### Fields
$TYPEDFIELDS
"""
struct JArray{T}
    size::Storage{Int}
    storage::Storage{T}
end
function native2jugsaw(x::Array{T}) where T
    return JArray(Storage(collect(Int, size(x))), Storage(vec(x)))
end
function jugsaw2native(t::JArray, demo::Array)
    typeof(demo)(reshape(t.storage, t.size...))
end

##### DataType
"""
$TYPEDEF

The type for specifying data type in Jugsaw.

### Fields
$TYPEDFIELDS
"""
struct JDataType
    name::String
    fieldnames::Storage{String}   # can not use tuple!
    fieldtypes::Storage{String}
end
function native2jugsaw(x::DataType)
    isconcretetype(x) || return JDataType(type2str(x), Storage(String[]), Storage(String[]))
    JDataType(type2str(x),
        Storage(String[string(x) for x in fieldnames(x)]),
        Storage(String[type2str(x) for x in x.types]))
end

# no need to define jugsaw2native, since it is handled manually.

# ##### Tuple
# function jugsaw2native(t::JugsawExpr)
#     ([adt2julia(v, d) for (v, d) in zip(getfields(t), demo)]...,)
# end
