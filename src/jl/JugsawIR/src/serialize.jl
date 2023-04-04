using DataStructures: OrderedDict
# Extended JSON
# https://github.com/JuliaIO/JSON.jl
# `json4` parse an object to string, which can be used to
# 1. parse a Julia object to a json object, with complete type specification.
# 2. parse a function specification to a json object, with complete input argument specification.
# `parse4` is the inverse of `json4`.
# potential issue: types with the same name in the same app may cause key conflict.
# error user if the type contains a __type__ field.

# the typed parsing
function json4(obj)
    JSON.json(todict(obj))
end

# type specification
function jsontype4(::Type{T}) where T
    types = OrderedDict{String, OrderedDict{String, Any}}()
    typedef!(types, T)
    return JSON.json(types)
end

function todict(@nospecialize(x::T)) where T
    @match x begin
        ###################### Basic Types ######################
        ::JSONTypes => x  # natively supported by JSON
        ::UndefInitializer => OrderedDict("__type__" => type2str(T), "data" => nothing)   # avoid undef parse error
        ::Float16 || ::Float32 => OrderedDict("__type__" => type2str(T), "data" => todict(Float64(x)))
        ::DataType => type2str(T)
        ::Char || ::Int8 || ::Int16 || ::Int32 || ::Int128 || 
            ::UInt8 || ::UInt16 || ::UInt32 || ::UInt128 ||
            ::Symbol || ::Missing => OrderedDict("__type__" => type2str(T), "data" => x)   # can not reduce anymore.
        ##################### Specified Types ####################
        ::Vector => [todict(v) for v in x]
        ::Array => OrderedDict(
                "__type__"=> type2str(typeof(x)),
                "size" => collect(Int, size(x)),
                "data"=> todict(vec(x))
            )
        ::Tuple => OrderedDict("__type__"=>type2str(typeof(x)), "data"=>[todict(v) for v in x])
        ::Dict{String} || ::OrderedDict{String} => OrderedDict(   # to protect a dict with `__type__` field.
            "__type__"=> type2str(typeof(x)),
            "data"=> Dict(k=>todict(v) for (k, v) in x)
        )
        ###################### Generic Compsite Types ######################
        _ => begin
            d = OrderedDict{String, Any}("__type__" => type2str(T))
            for fn in fieldnames(T)
                d[String(fn)] = isdefined(x, fn) ? todict(getfield(x, fn)) : nothing
            end
            d
        end
    end
end

function typedef!(types::AbstractDict, @nospecialize(t::Type{T})) where T
    haskey(types, T) && return
    sT = type2str(T)
    (startswith(sT, "Primitive") || startswith(sT, "Abstract")) && error("Keywords `Primitive` and `Abstract` are protected!")
    @match T begin
        ::BasicTypes || ::Type{Any} => "Primitive{$sT}"  # wrap primitive type
        # ::Type{<:Enum} => begin
        #     types[sT] = OrderedDict("__type__"=>"DataType",
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
            d = OrderedDict{String, String}()
            for (n, t) in zip(fieldnames(T), T.types)
                d[string(n)] = typedef!(types, t)
            end
            # show self
            types[sT] = OrderedDict("__type__"=>"DataType",
                        "name" => sT,
                        "fields" => d
                    )
            sT
        end
        _ => "Abstract{$sT}"
    end
end