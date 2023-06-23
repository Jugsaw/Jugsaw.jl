"""
    native2jugsaw(object)

Convert a native Julia object to a Jugsaw compatible object.
"""
native2jugsaw(x) = x
native2jugsaw(x::Vector) = x

"""
    construct_object(adt::JugsawADT, demo_object)

Reconstruct the native Julia object from an object of type [`JugsawADT`](@ref).
The return value must have the same data type as the second argument.
"""
function construct_object end

aslist(obj) = obj.fields[2].storage

##### Dict
"""
$TYPEDEF

The dictionary type in Jugsaw, which represents a dictionary in key-value pairs.

### Fields
$TYPEDFIELDS
"""
struct JDict{K, V}
    pairs::Vector{Pair{K, V}}
end

function native2jugsaw(x::Dict)
    JDict(collect(x))
end
function construct_object(t::JugsawADT, demo::AbstractDict{T, V}) where {T, V}
    # TODO: fix this bad implementation
    pairs = adt2julia(t.fields[1], isempty(demo) ? Pair{T,V}[] : collect(demo))
    typeof(demo)(pairs)
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
    options::Vector{String}
end
function native2jugsaw(x::Enum)
    JEnum(type2str(typeof(x)), string(x), String[string(v) for v in instances(typeof(x))])
end
function construct_object(t::JugsawADT, demo::Enum)
    kind, value, options = t.fields
    typeof(demo)(findfirst(==(value), aslist(options))-1)
end
function construct_object(value::String, demo::Enum)
    idx = findfirst(x->string(x)==(value), instances(typeof(demo)))
    typeof(demo)(idx-1)
end

##### JArray
"""
$TYPEDEF

The data type for arrays in Jugsaw.

### Fields
$TYPEDFIELDS
"""
struct JArray{T}
    size::Vector{Int}
    storage::Vector{T}
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
    fieldnames::Vector{String}   # can not use tuple!
    fieldtypes::Vector{String}
end
function native2jugsaw(x::DataType)
    isconcretetype(x) || return JDataType(type2str(x), String[], String[])
    JDataType(type2str(x), String[string(x) for x in fieldnames(x)], String[type2str(x) for x in x.types])
end

##### Tuple
function construct_object(t::JugsawADT, demo::Tuple)
    ([adt2julia(v, d) for (v, d) in zip(t.fields, demo)]...,)
end
