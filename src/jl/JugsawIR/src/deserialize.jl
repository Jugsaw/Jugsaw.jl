macro parsetype(T, target)
    return esc(:($parsetype($__module__, $T, $target)))
end
# NOTE: we prefer T(...) instead of convert because Symbol-String can not be casted by convert.
# primitive types
for T2 in [:String, :Int, :Float64, :Bool]  # null type?
    @eval parsetype(::Module, ::Type{T}, target::$T2) where T = T(target)
    @eval parsetype(::Module, ::Type{Any}, target::$T2) = target
end
# Nothing -> Any
parsetype(::Module, ::Type{Any}, ::Nothing) = nothing
# Nothing -> Nothing
parsetype(::Module, ::Type{Nothing}, ::Nothing) = nothing

# Vector -> Any
parsetype(m::Module, ::Type{Any}, target::Vector) = target
# Vector -> Vector
parsetype(m::Module, ::Type{Vector{T}}, target::Vector) where T = T[parsetype.(Ref(m), Ref(T), target)...]
# Vector -> Tuple
function parsetype(m::Module, ::Type{T1}, target::Vector) where T1 <: Tuple
    @assert length(T1.types) == length(target) "can not parse $target into a tuple of type $T1"
    ntuple(i->parsetype(m, T1.types[i], target[i]), length(T1.types))
end
# Vector to named tuple
# parsetype(m::Module, ::Type{T1}, target::Vector) where T1 <: NamedTuple = parsetype(m, T1, Dict(target))

# Dict -> Any
function parsetype(m::Module, ::Type{Any}, target::AbstractDict{T2}) where {T2}
    if haskey(target, "__type__")
        specified_type = str2type(m, target["__type__"])
        if specified_type !== Any
            return cumstomized_parsetype(m, specified_type, target)
        end
    end
    # parse its value, in case its value contains type information
    res = Pair{T2, Any}[]
    for (k, v) in target
        push!(res, k=>parsetype(m, Any, v))
    end
    #res = map(kv->(kv.first=>parsetype(Any, kv.second)), target)
    return Dict(res)
end
# Dict -> Dict
function parsetype(m::Module, ::Type{Dict{T1, T2}}, target::AbstractDict) where {T1, T2}
    d = Dict{T1, T2}()
    for (k, v) in target
        d[T1(k)] = parsetype(m, T2, v)
    end
    return d
end
# Dict -> generic types
function parsetype(m::Module, ::Type{T}, target::AbstractDict{T2}) where {T, T2}
    cumstomized_parsetype(m, T, target)
end
#   -> primitive arrays
function cumstomized_parsetype(m::Module, ::Type{Array{T, N}}, target::AbstractDict) where {T<:ArrayPrimitiveTypes, N}
    reshape(collect(reinterpret(T, base64decode(target["storage"]))), target["size"]...)
end

function cumstomized_parsetype(m::Module, ::Type{T}, target::AbstractDict{T2}) where {T<:Tuple, T2}
    return T(target["$i"] for i in fieldnames(T))
end
#   -> generic types
@generated function cumstomized_parsetype(m::Module, ::Type{T}, target::AbstractDict{T2}) where {T, T2}
    #   -> data types
    if T == DataType
        return :(str2type(m, target["name"]))
    end
    # quote node because the key can be a Symbol
    fields = fieldnames(T)
    Expr(:new, T, Any[:(parsetype(m, $(T.types[i]), target[$(QuoteNode(T2(fields[i])))])) for i=1:length(T.types)]...)
end

#function parsetype(m::Module, ::Type{T1}, target::Dict{K}) where {T1 <: NamedTuple, K}
#    syms, types = T1.parameters
#    typedict = Dict(zip(syms, types.parameters))
#    NamedTuple(Symbol(k)=>parsetype(m, get(typedict, Symbol(k), Any), v) for (k, v) in target)
#end

# String -> Enum
function parsetype(m::Module, ::Type{T}, target::String) where {T<:Enum}
    return getfield(m, Meta.parse(target))
end

# string as type and type to string
function str2type(m::Module, str::String)
    try
        ex = Meta.parse(str)
        if ex isa Symbol || (ex isa Expr && ex.head == :curly)
            # TODO: make sure eval is safe for :curly
            return Core.eval(m, ex)
        else
            @warn "string can not be parsed to a type: $str"
            return Any
        end
    catch e
        @warn "string can not be parsed to a type: $str, got error: $e"
        return Any
    end
end