# Extended JSON
# https://github.com/JuliaIO/JSON.jl
# `json4` parse an object to string, which can be used to
# 1. parse a Julia object to a json object, with complete type specification.
# 2. parse a function specification to a json object, with complete input argument specification.
# `parse4` is the inverse of `json4`.
# potential issue: types with the same name in the same app may cause key conflict.
# error user if the type contains a type field.

# the typed parsing
function json4(obj)
    JSON.json(todict(obj))
end

# type specification
function jsontype4(::Type{T}) where T
    types = Dict{String, Any}()
    typedef!(types, T)
    return JSON.json(types)
end

function todict(@nospecialize(x::T)) where T
    @match x begin
        ###################### Basic Types ######################
        ::JSONTypes => x  # natively supported by JSON
        ::UndefInitializer => Dict(
            "type" => type2str(T),
            "fields"=>String[],
            "values" => []
        )   # avoid undef parse error
        ::Float16 || ::Float32 => Dict(
            "type" => type2str(T),
            "fields"=>String[],
            "values" => [Float64(x)]
        )
        ::DataType => type2str(x)
        ::UnionAll => type2str(x)
        ::Union => type2str(x)
        ::Char || ::Int8 || ::Int16 || ::Int32 || ::Int128 || 
            ::UInt8 || ::UInt16 || ::UInt32 || ::UInt128 ||
            ::Symbol || ::Missing => Dict(
                "type" => type2str(T),
                "fields"=>String[],
                "values" => [x]
            )   # can not reduce anymore.
        ##################### Specified Types ####################
        ::Array => Dict(
            "type"=> type2str(typeof(x)),
            "fields"=> ["size", "storage"],
            "values" => [collect(Int, size(x)), map(todict, vec(x))]
        )
        ::Tuple => Dict(
            "type"=>type2str(typeof(x)),
            "fields"=>["$i" for i=1:length(x)],
            "values"=>map(todict, x)
        )
        ::Dict => Dict(
            "type"=> type2str(typeof(x)),
            "fields" => ["keys", "values"],
            "values"=> [[todict(k) for k in keys(x)], [todict(v) for v in values(x)]]
        )
        ###################### Generic Compsite Types ######################
        _ => Dict{String, Any}(
                "type" => type2str(T),
                "fields" => String.(fieldnames(T)),
                "values" => map(fn->isdefined(x, fn) ? todict(getfield(x, fn)) : nothing, fieldnames(T))
            )
    end
end

function typedef!(types::AbstractDict, @nospecialize(t::Type{T})) where T
    sT = type2str(T)
    haskey(types, T) && return sT
    (startswith(sT, "Primitive") || startswith(sT, "Abstract")) && error("Keywords `Primitive` and `Abstract` are protected!")
    @match T begin
        ::Type{<:BasicTypes} || ::Type{Any} => begin
            types[sT] = "Primitive{$sT}"
            sT
        end  # wrap primitive type
        # ::Type{<:Enum} => begin
        #     types[sT] = Dict("type"=>"DataType",
        #                 "name"=>sT,
        #                 "instances"=>string.(instances(T))
        #         )
        #     sT
        # end
        IsConcreteType() => begin  # generic composite type
            # define parameter types
            for t in T.parameters
                if t isa Type
                    typedef!(types, t)
                end
            end
            # define field types recursively
            d = Dict{String, String}()
            for (n, t) in zip(fieldnames(T), T.types)
                d[string(n)] = typedef!(types, t)
            end
            # show self
            types[sT] = Dict("type"=>"DataType",
                        "name" => sT,
                        "fields" => d
                    )
            sT
        end
        _ => begin
            types["$sT}"] = "Abstract{$sT}"
            sT
        end
    end
end