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
    meta::Dict{String, String}
end
function JDataType(x::DataType)
    isconcretetype(x) || return JDataType(type2str(x), String[], String[])
    JDataType(type2str(x),
        String[string(x) for x in fieldnames(x)],
        String[type2str(x) for x in x.types],
        Dict("docstring"=>description(x)))
end

############ TypeTable
"""
$(TYPEDEF)

The type definitions.

### Fields
$(TYPEDFIELDS)

The `defs` defines a mapping from the type name to a [`JDataType`](@ref) instance.
"""
struct TypeTable
    names::Vector{String}
    defs::Dict{String, JDataType}
end
TypeTable() = TypeTable(String[], Dict{String, Tuple{Vector{String}, Vector{String}}}())
function pushtype!(tt::TypeTable, type::Type{T}) where T
    JT = native2jugsaw(T)
    if !haskey(tt.defs, JT.name)
        push!(tt.names, JT.name)
        tt.defs[JT.name] = JT
    end
    return tt
end
Base.show(io::IO, ::MIME"text/plain", t::TypeTable) = Base.show(io, t)
function Base.show(io::IO, t::TypeTable)
    println(io, "TypeTable")
    for (k, typename) in enumerate(t.names)
        println(io, "  - $typename")
        if !haskey(t.defs, typename)
            println(io, "    - not exist")
            continue
        end
        type = t.defs[typename]
        fns, fts = type.fieldnames, type.fieldtypes
        for (l, (fn, ft)) in enumerate(zip(fns, fts))
            print(io, "    - $fn::$ft")
            if !(k == length(t.names) && l == length(fns))
                println(io)
            end
        end
    end
end
function Base.merge!(t1::TypeTable, t2::TypeTable)
    for name in t2.names
        pushtype!(t1, t2.defs[name])
    end
    return t1
end

####################
# the string representation of basic types
function type2str(::Type{T}) where T
    if T === Any   # the only abstract type
        return "Core.Any"
    elseif !isconcretetype(T)
        if T isa DataType
            typename = "$(modname(T)).$(string(T))"
        elseif T isa UnionAll
            typename = "$(modname(T)).$(string(T))"
        elseif T isa Union
            typename = string(T)
        else
            @warn "type category unknown: $T"
            typename = string(T)
        end
    elseif length(T.parameters) > 0 || T === Tuple{}
        typename = "$(modname(T)).$(_nosharp(T.name.name)){$(join([p isa Type ? type2str(p) : repr(p) for p in T.parameters], ", "))}"
    else
        typename = "$(modname(T)).$(_nosharp(T.name.name))"
    end
    return typename
end
# remove `#` from the function name to avoid parsing error
function _nosharp(s::Symbol)
    s = strip(String(s), '#')
    return first(split(s, "#"))
end
function modname(T::DataType)
    mod = T.name.module
    return string(mod)
end
function modname(T::UnionAll)
    return modname(T.body)
end

# string as type and type to string
function str2type(m::Module, str::String)
    ex = Meta.parse(str)
    @match ex begin
        :($mod.$name{$(paras...)}) || :($mod.$name) ||
            ::Symbol || :($name{$(paras...)}) => Core.eval(m, ex)
        _ => Any
    end
end

value_type(::AbstractDict{T, V}) where {T,V} = V
key_type(::AbstractDict{T}) where {T} = T