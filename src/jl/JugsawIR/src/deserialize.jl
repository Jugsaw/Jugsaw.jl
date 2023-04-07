# main interfaces
function parse4(str::AbstractString;
               type = Any,
               mod = @__MODULE__,
               dicttype=OrderedDict{String,Any},
               inttype::Type{<:Real}=Int64,
               allownan::Bool=true,
               null=nothing)
    fromdict(mod, type, JSON.parse(str; dicttype, inttype, allownan, null))
end

function fromdict(m::Module, @nospecialize(t::Type{T}), @nospecialize(d)) where T
    if !isconcretetype(T) && T !== Any
        @warn "Abstract type information (useless) found: $T"
        return fromdict(m, Any, d)
    end
    @match T begin
        ###################### Basic Types ######################
        ::Type{<:JSONTypes} => d
        ::Type{Float32} || ::Type{Float16} => T(fromdict(m, Float64, d["data"]))
        ::Type{UndefInitializer} => undef
        ::Type{Missing} => missing
        ::Type{Char} || ::Type{Int8} || ::Type{Int16} || ::Type{Int32} || ::Type{Int128} || 
            ::Type{UInt8} || ::Type{UInt16} || ::Type{UInt32} || ::Type{UInt128} ||
            ::Type{Symbol} => T(d["data"])
        ::Type{DataType} => str2type(m, d)
        # NOTE: to get rid of type cast, we should use demo to deserialize an object.
        ::Type{UnionAll} => str2type(m, d)
        ::Type{Union} => str2type(m, d)
        ##################### Specified Types ####################
        ::Type{<:Vector} => eltype(T)[fromdict(m, eltype(T), v) for v in d]
        ::Type{<:Array} => reshape(fromdict(m, Vector{eltype(T)}, d["data"]), d["size"]...)
        ::Type{<:Tuple} => begin
            ([fromdict(m, T.parameters[i], v) for (i, v) in enumerate(d["data"])]...,)
        end
        ::Type{<:Dict{String}} || ::Type{<:OrderedDict{String}} ||
            ::Type{<:Dict{Symbol}} || ::Type{<:OrderedDict{Symbol}} ||
            ::Type{<:Dict{Int}} || ::Type{<:OrderedDict{Int}} => T(cast_key(key_type(T), k)=>fromdict(m, value_type(T), v) for (k, v) in d["data"])

        ###################### Generic Compsite Types ######################
        ::Type{Any} => begin
            if d isa JSONTypes
                d
            elseif d isa Vector
                [fromdict(m, Any, v) for v in d]
            elseif haskey(d, "__type__")
                specified_type = str2type(m, d["__type__"])
                if isconcretetype(specified_type)
                    fromdict(m, specified_type, d)
                else
                    @warn "Abstract type information (useless) found: $specified_type"
                    Dict(k=>fromdict(m, Any, v) for (k, v) in d)
                end
            else
                # parse its value, in case its value contains type information
                @warn "no type information found, parsing to dict!"
                Dict(k=>fromdict(m, Any, v) for (k, v) in d)
            end
        end
        IsConcreteType() => begin
            names = fieldnames(T)
            vals = filter!(x->x!==undef, Any[fromdict(m, T.types[i], d[String(names[i])]) for i=1:length(T.types)])
            #generic_customized_parsetype(m, T, Tuple(values))
            Core.eval(m, Expr(:new, T, Any[:($vals[$i]) for i=1:length(vals)]...))
        end
    end
end
value_type(::Type{<:AbstractDict{T, V}}) where {T,V} = V
key_type(::Type{<:AbstractDict{T}}) where {T} = T
cast_key(::Type{String}, s::String) = s
cast_key(::Type{Int}, s::String) = parse(Int, s)
cast_key(::Type{Symbol}, s::String) = Symbol(s)

#   -> generic types (undef handled)
# @generated function generic_customized_parsetype(m::Module, ::Type{T}, values::NTuple{N,Any}) where {T,N}
#     #   -> data types
#     # quote node because the key can be a Symbol
#     Expr(:new, T, Any[:(values[$i]) for i=1:N]...)
# end

# string as type and type to string
function str2type(m::Module, str::String)
    ex = Meta.parse(str)
    @match ex begin
        :($mod.$name{$(paras...)}) || :($mod.$name) ||
            ::Symbol || :($name{$(paras...)}) => Core.eval(m, ex)
        _ => Any
    end
end

