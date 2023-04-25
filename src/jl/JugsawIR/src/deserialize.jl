# main interfaces
function parse4(str::AbstractString;
               type = Any,
               mod = @__MODULE__,
               dicttype=Dict{String,Any},
               inttype::Type{<:Real}=Int64,
               allownan::Bool=true,
               null=nothing)
    fromdict(mod, type, JSON.parse(str; dicttype, inttype, allownan, null))
end

# TODO: parse by demo!
function fromdict(m::Module, @nospecialize(t::Type{T}), d) where T
    if !isconcretetype(T) && T !== Any
        @warn "Abstract type information (useless) found: $T"
        return fromdict(m, Any, d)
    end
    @match T begin
        ###################### Basic Types ######################
        ::Type{<:JSONTypes} => d
        ::Type{Float32} || ::Type{Float16} => T(d["values"][])
        ::Type{UndefInitializer} => undef
        ::Type{Missing} => missing
        ::Type{Char} || ::Type{Int8} || ::Type{Int16} || ::Type{Int32} || ::Type{Int128} || 
            ::Type{UInt8} || ::Type{UInt16} || ::Type{UInt32} || ::Type{UInt128} ||
            ::Type{Symbol} => T(d["values"][])
        ::Type{DataType} => str2type(m, d)
        # NOTE: to get rid of type cast, we should use demo to deserialize an object.
        ::Type{UnionAll} => str2type(m, d)
        ::Type{Union} => str2type(m, d)
        ##################### Specified Types ####################
        ::Type{<:Array} => reshape(eltype(T)[fromdict(m, eltype(T), x) for x in d["values"][2]], Int.(d["values"][1])...)
        ::Type{<:Enum} => T(findfirst(==(d["values"][2]), d["values"][3])-1)
        ::Type{<:Tuple} => begin
            ([fromdict(m, T.parameters[i], v) for (i, v) in enumerate(d["values"])]...,)
        end
        ::Type{<:Dict} => T(zip(
                map(k->fromdict(m, key_type(T), k), d["values"][1]),
                map(v->fromdict(m, value_type(T), v), d["values"][2])
            )
        )

        ###################### Generic Compsite Types ######################
        ::Type{Any} => begin
            if d isa JSONTypes
                d
            #elseif d isa Vector
                #[fromdict(m, Any, v) for v in d]
            #elseif haskey(d, "type")
            else
                @assert d isa Dict && length(d) >= 2 "type parsing fail, missing data information! got: $d"
                specified_type = str2type(m, d["type"])
                if isconcretetype(specified_type)
                    fromdict(m, specified_type, d)
                else
                    @warn "Abstract type information (useless) found: $specified_type"
                    Dict(k=>fromdict(m, Any, v) for (k, v) in d)
                end
            #else
                # parse its value, in case its value contains type information
                #@warn "no type information found, parsing to dict!"
                #Dict(k=>fromdict(m, Any, v) for (k, v) in d)
            end
        end
        IsConcreteType() => begin
            @info d
            vals = filter!(x->x!==undef, Any[fromdict(m, T.types[i], d["values"][i]) for i=1:length(T.types)])
            #generic_customized_parsetype(m, T, Tuple(values))
            Core.eval(m, Expr(:new, T, Any[:($vals[$i]) for i=1:length(vals)]...))
        end
    end
end

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

