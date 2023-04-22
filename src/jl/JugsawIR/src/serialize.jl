# Extended JSON
# https://github.com/JuliaIO/JSON.jl
# `json4` parse an object to string, which can be used to
# 1. parse a Julia object to a json object, with complete type specification.
# 2. parse a function specification to a json object, with complete input argument specification.
# `parse4` is the inverse of `json4`.

# the typed parsing
function json4(obj)
    JSON.json(todict(obj))
end

# type specification
function jsontype4(::Type{T}) where T
    types = []
    typedef!(types, T, Dict{Any,String}())
    return JSON.json(types)
end

# data are dumped to (name, value[, fieldnames])
function todict(@nospecialize(x::T)) where T
    @match x begin
        ###################### Basic Types ######################
        ::JSONTypes => x  # natively supported by JSON
        ::UndefInitializer => Any[type2str(T),
            [],
            String[],
        ]   # avoid undef parse error
        ::Float16 || ::Float32 => Any[
            type2str(T),
            [Float64(x)],
            String["storage"],
        ]
        ::DataType => type2str(x)
        ::UnionAll => type2str(x)
        ::Union => type2str(x)
        ::Char || ::Int8 || ::Int16 || ::Int32 || ::Int128 || 
            ::UInt8 || ::UInt16 || ::UInt32 || ::UInt128 ||
            ::Symbol || ::Missing => Any[
                type2str(T),
                [x],
                String["storage"],
            ]   # can not reduce anymore.
        ##################### Specified Types ####################
        ::Array => Any[
            type2str(typeof(x)),
            [collect(Int, size(x)), map(todict, vec(x))],
            ["size", "storage"],
        ]
        ::Enum => Any[
            type2str(typeof(x)),
            ["DataType", string(x), String[string(v) for v in instances(typeof(x))]],
            ["kind", "value", "options"],
        ]
        ::Tuple => Any[
            type2str(typeof(x)),
            map(todict, x),
            ["$i" for i=1:length(x)],
        ]
        ::Dict => Any[
            type2str(typeof(x)),
            [[todict(k) for k in keys(x)], [todict(v) for v in values(x)]],
            ["keys", "values"],
        ]
        ###################### Generic Compsite Types ######################
        _ => Any[
                type2str(T),
                map(fn->isdefined(x, fn) ? todict(getfield(x, fn)) : nothing, fieldnames(T)),
                String.(fieldnames(T)),
            ]
    end
end

function typedef!(types::Vector{Any}, @nospecialize(t::Type{T}), typedict::Dict{Any, String}) where T
    sT = type2str(T)
    haskey(typedict, T) && return sT
    ret = @match T begin
        ::Type{<:BasicTypes} || ::Type{Any} => begin
            push!(types, sT)
            sT
        end  # wrap primitive type
        ##################### Specified Types ####################
        ::Type{<:Array} => begin
            def_typeparams!(T, types, typedict)
            push!(types, create_type(sT, ["size", "storage"], [type2str(Vector{Int}), type2str(Vector{eltype(T)})]))
            sT
        end
        ::Type{<:Dict} => begin
            def_typeparams!(T, types, typedict)
            push!(types, create_type(sT, ["keys", "values"], [type2str(Vector{key_type(T)}), type2str(Vector{value_type(T)})]))
            sT
        end
        ::Type{<:Enum} => begin
            push!(types, create_type("Jugsaw.Universe.Enum", ["kind", "value", "options"], [type2str(String), type2str(Vector{String})]))
            sT
        end
        ###################### Generic Compsite Types ######################
        IsConcreteType() => begin  # generic composite type
            # define parameter types
            def_typeparams!(T, types, typedict)
            # define field types recursively
            d = String[]
            dT = String[]
            for (n, t) in zip(fieldnames(T), T.types)
                push!(d, string(n))
                push!(dT, typedef!(types, t, typedict))
                sT
            end
            # show self
            push!(types, create_type(sT, d, dT))
            sT
        end
        _ => begin
            push!(types, sT)
            sT
        end
    end
    typedict[T] = ret
    return ret
end

function def_typeparams!(::Type{T}, types, typedict) where T
    for t in T.parameters
        if t isa Type
            typedef!(types, t, typedict)
        end
    end
end

function create_type(name::String, fieldnames::Vector{String}, fieldtypes::Vector{String})
    ["DataType", [name, fieldnames, fieldtypes], ["name", "fieldnames", "fieldtypes"]]
end