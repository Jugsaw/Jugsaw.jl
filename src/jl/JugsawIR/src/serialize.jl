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

struct TypeTable
    names::Vector{String}
    defs::Dict{String, Tuple{Vector{String}, Vector{String}}}
end
function deftype!(tt::TypeTable, name::String, fieldnames::Vector{String}, fieldtypes::Vector{String})
    if !haskey(tt.defs, name)
        push!(tt.names, name)
        tt.defs[name] = (fieldnames, fieldtypes)
    end
end

function def!(tt::TypeTable, name::String, fieldnames::Vector{String}, @nospecialize(fieldvalues::Tuple))
    deftype!(tt, name, fieldnames, [type2str(typeof(x)) for x in fieldvalues])
    create_obj(name, collect(Any, fieldvalues))
end

# data are dumped to (name, value[, fieldnames])
function todict!(@nospecialize(x::T), tt::TypeTable) where T
    sT = type2str(T)
    @match x begin
        ###################### Basic Types ######################
        ::JSONTypes => x  # natively supported by JSON
        ::UndefInitializer => begin
            # avoid undef parse error
            def!(tt, sT, String[], String[])
        end
        ::Float16 || ::Float32 => def!(tt, sT, ["content"], [Float64(x)])
        ::DataType => begin
        # FROM HERE!
            def!(tt, "DataType", ["name", "fieldnames", "fieldtypes"], [type2str(String), type2str(Vector{String}), type2str(Vector{String})])
        end
        ::UnionAll => type2str(x)
        ::Union => type2str(x)
        ::Char || ::Int8 || ::Int16 || ::Int32 || ::Int128 || 
            ::UInt8 || ::UInt16 || ::UInt32 || ::UInt128 ||
            ::Symbol || ::Missing => create_obj(
                type2str(T),
                [x],
               )   # can not reduce anymore.
        ##################### Specified Types ####################
        ::Array => create_obj(
            type2str(typeof(x)),
            [collect(size(x)), map(todict, vec(x))],
        )
        ::Enum => create_obj(
            type2str(typeof(x)),
            ["DataType", string(x), String[string(v) for v in instances(typeof(x))]],
        )
        ::Tuple => create_obj(
            type2str(typeof(x)),
            map(todict, x),
        )
        ::Dict => begin
            push!(types, create_type(sT, ["keys", "vals"], [type2str(Vector{key_type(T)}), type2str(Vector{value_type(T)})]))
            create_obj(
                type2str(typeof(x)),
                [[todict(k) for k in keys(x)], [todict(v) for v in values(x)]],
            )
        end
        ###################### Generic Compsite Types ######################
        _ => create_obj(
                type2str(T),
                map(fn->isdefined(x, fn) ? todict(getfield(x, fn)) : nothing, fieldnames(T)),
            )
    end
end

function create_obj(type, values)
    return Dict("type"=>type, "values"=>values)
end

function typedef!(types::Vector{Any}, @nospecialize(t::Type{T}), typedict::Dict{Any, String}) where T
    sT = type2str(T)
    haskey(typedict, T) && return sT
    ret = @match T begin
        ::Type{<:BasicTypes} || ::Type{Any} => begin
            push!(types, sT)
            sT
        end  # wrap primitive type
        ::Type{DataType} => begin
            push!(types, create_type("DataType", ["name", "fieldnames", "fieldtypes"],
                [type2str(String), type2str(Vector{String}), type2str(Vector{String})]))
            sT
        end
        ##################### Specified Types ####################
        ::Type{<:Array} => begin
            def_typeparams!(T, types, typedict)
            push!(types, create_type(sT, ["size", "storage"], [type2str(Vector{Int}), type2str(Vector{eltype(T)})]))
            sT
        end
        ::Type{<:Dict} => begin
            def_typeparams!(T, types, typedict)
            push!(types, create_type(sT, ["keys", "vals"], [type2str(Vector{key_type(T)}), type2str(Vector{value_type(T)})]))
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
    Dict(
        "type" => "DataType",
        "values" => [name, fieldnames, fieldtypes],
        "fields" => ["name", "fieldnames", "fieldtypes"]
    )
end