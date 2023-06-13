native2jugsaw(x) = x
native2jugsaw(x::Vector) = x

##### Dict
struct JDict{K, V}
    keys::Vector{K}
    vals::Vector{V}
end
function native2jugsaw(x::Dict)
    JDict(collect(keys(x)), collect(values(x)))
end
function construct_object(t::JugsawADT, demo::Dict)
    # TODO: fix this bad implementation
    ks = adt2julia(t.fields[1], collect(keys(demo)))
    vs = adt2julia(t.fields[2], collect(values(demo)))
    typeof(demo)(zip(ks, vs))
end

##### Enum
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
    typeof(demo)(findfirst(==(value), options.fields[2].storage)-1)
end

##### JArray
struct JArray{T}
    size::Vector{Int}
    storage::Vector{T}
end

##### DataType
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