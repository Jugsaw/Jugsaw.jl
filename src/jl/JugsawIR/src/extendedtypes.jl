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
    ks, vs = t.fields
    kd, vd = length(demo) > 0 ? (first(keys(demo)), first(values(demo))) : (demoof(key_type(demo)), demoof(value_type(demo)))
    typeof(demo)(zip([adt2julia(k, kd) for k in ks],
        [adt2julia(v, vd) for v in vs]))
end

##### Array
struct JArray{T}
    size::Vector{Int}
    storage::Vector{T}
    function JArray(size, storage::Vector{T}) where T
        if length(size) == 1
            error("array of rank 1 is deliberately not supported.")
        end
        return new{T}(size, storage)
    end
end
function native2jugsaw(x::Array)
    JArray(collect(size(x)), vec(x))
end
function construct_object(t::JugsawADT, demo::Array{T}) where T
    size, storage = t.fields
    d = demoofarray(demo)
    reshape(T[adt2julia(x, d) for x in storage], Int[adt2julia(s, 0) for s in size]...)
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
    typeof(demo)(findfirst(==(value), options)-1)
end

##### DataType
struct JDataType
    name::String
    fieldnames::Vector{String}
    fieldtypes::Vector{String}
end
function native2jugsaw(x::DataType)
    isabstracttype(x) && return JDataType(type2str(x), String[], String[])
    JDataType(type2str(x), String[String(fi) for fi in fieldnames(x)], String[type2str(x) for x in x.types])
end

##### Tuple
function construct_object(t::JugsawADT, demo::Tuple)
    ([adt2julia(v, d) for (v, d) in zip(t.fields, demo)]...,)
end