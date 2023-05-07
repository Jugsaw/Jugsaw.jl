# JugsawIR code -> Lerche.Tree -> JugsawADT <-> Julia
#       ↑                            ↓
#       <-----------------------------
using Expronicon
using Expronicon.ADT: @adt
export tree2adt

@adt JugsawADT begin
    struct Object
        typename::String
        fields::Vector
    end
    struct Call
        fname::String
        args::Vector
        kwargnames::Vector{String}
        kwargvalues::Vector
    end
    struct Type
        name::String
        fieldnames::Vector{String}
        fieldtypes::Vector{String}
    end
    struct Dict
        keys::Vector
        vals::Vector
    end
    struct Array
        size::Vector{Int}
        storage::Vector
    end
    struct Enum
        kind::String
        value::String
        options::Vector{String}
    end
end
Base.:(==)(a::JugsawADT, b::JugsawADT) = all(fn->getfield(a, fn) == getfield(b, fn), fieldnames(JugsawADT))
Base.show(io::IO, ::MIME"text/plain", a::JugsawADT) = Base.show(io, a)
function Base.show(io::IO, a::JugsawADT)
    @match a begin
        JugsawADT.Object(typename, fields) => print(io, "$typename($(join(fields, ", ")))")
        JugsawADT.Call(fname, args, kwargnames, kwargvalues) => print(io, "$fname($(join(repr.(args), ", ")); $(join(["$k=$(repr(v))" for (k, v) in zip(kwargnames, kwargvalues)], ", ")))")
        JugsawADT.Type(name, fns, fieldtypes) => print(io, "$name($(join(["$n::$t" for (n, t) in zip(fns, fieldtypes)], ", ")))")
        JugsawADT.Array(size, storage) => print(io, "Array($size, $storage)")
        JugsawADT.Dict(keys, values) => print(io, "Dict($(join(["$k=$v" for (k, v) in zip(keys, values)], ", ")))")
        JugsawADT.Enum(kind, value, options) => print(io, "$kind($value, $options)")
    end
end

struct TypeTable
    names::Vector{String}
    defs::Dict{String, DataType}
end
TypeTable() = TypeTable(String[], Dict{String, Tuple{Vector{String}, Vector{String}}}())
function pushtype!(tt::TypeTable, type::Type{T}) where T
    sT = type2str(T)
    if !haskey(tt.defs, sT)
        push!(tt.names, sT)
        tt.defs[sT] = T
    end
    return tt
end
Base.show(io::IO, ::MIME"text/plain", t::TypeTable) = Base.show(io, t)
function Base.show(io::IO, t::TypeTable)
    println(io, "TypeTable")
    for (k, typename) in enumerate(t.names)
        println(io, "  - $typename")
        fns, fts = get(t.defs, typename, ([], []))
        for (l, (fn, ft)) in enumerate(zip(fns, fts))
            print(io, "    - $fn::$ft")
            if !(k == length(t.names) && l == length(fns))
                println()
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

########################## Julia to ADT
# returns the object and type specification
function julia2adt(@nospecialize(x::T)) where T
    tt = TypeTable()
    res = julia2adt!(x, tt)
    # dump type table
    ttres = julia2adt!(tt, TypeTable())
    return res, ttres
end

function get_fieldnames(::Type{T}) where T
    @match T begin
        ::Type{<:Array} => ["size", "storage"]
        ::Type{<:Dict} => ["keys", "vals"]
        ::Type{<:DataType} => ["name", "fieldnames", "fieldtypes"]
        ::Type{<:Enum} => ["kind", "value", "options"]
        _ => begin
            if isabstracttype(T)
                String[]
            else
                String[string(fn) for fn in fieldnames(T)]
            end
        end
    end
end

# data are dumped to (name, value[, fieldnames])
function julia2adt!(@nospecialize(x::T), tt::TypeTable) where T
    (x isa UndefInitializer || x isa DirectlyRepresentableTypes) && pushtype!(tt, T)
    @match x begin
        ###################### Basic Types ######################
        ::UndefInitializer => nothing
        ::DirectlyRepresentableTypes => x
        ##################### Specified Types ####################
        ::DataType => begin
            JugsawADT.Type(type2str(x), get_fieldnames(x), String[type2str(x) for x in x.types])
        end
        ::Array => begin
            JugsawADT.Array(collect(size(x)), map(x->julia2adt!(x, tt), vec(x)))
        end
        ::Enum => begin
            JugsawADT.Enum(type2str(T), string(x), String[string(v) for v in instances(typeof(x))])
        end
        ::Dict => begin
            JugsawADT.Dict([julia2adt!(k, tt) for k in keys(x)], [julia2adt!(v, tt) for v in values(x)])
        end
        ###################### Generic Compsite Types ######################
        _ => begin
            JugsawADT.Object(type2str(T), 
                Any[isdefined(x, fn) ? julia2adt!(getfield(x, fn), tt) : undef for fn in fieldnames(T)]
            )
        end
    end
end

###################### ADT to julia
function adt2julia(t, demo::T) where T
    @match demo begin
        ###################### Basic Types ######################
        ::Nothing || ::Missing || ::UndefInitializer => demo
        ::Char => T(t[1])
        ::DirectlyRepresentableTypes => T(t)

        ##################### Specified Types ####################
        ::Type || ::Function => demo
        ::Array => begin
            size, storage = t.size, t.storage
            d = length(demo) > 0 ? first(demo) : demoof(eltype(demo))
            reshape(eltype(T)[adt2julia(x, d) for x in storage], Int[adt2julia(s, 0) for s in size]...)
        end
        ::Enum => begin
            value, options = t.value, t.options
            T(findfirst(==(value), options)-1)
        end
        ::Tuple => begin
            ([adt2julia(v, d) for (v, d) in zip(t.fields, demo)]...,)
        end
        ::Dict => begin
            ks, vs = t.keys, t.vals
            kd, vd = length(demo) > 0 ? (first(keys(demo)), first(values(demo))) : (demoof(key_type(demo)), demoof(value_type(demo)))
            T(zip([adt2julia(k, kd) for k in ks],
              [adt2julia(v, vd) for v in vs]))
        end

        ###################### Generic Compsite Types ######################
        _ => begin
            nfields(demo) == 0 ? demo : construct_object(t, demo)
        end
    end
end
function construct_object(t::JugsawADT, demo::T) where T
    flds = t.fields
    vals = [adt2julia(flds[i], getfield(demo, fn)) for (i, fn) in enumerate(fieldnames(T)) if isdefined(demo, fn)]
    return Core.eval(@__MODULE__, Expr(:new, T, Any[:($vals[$i]) for i=1:length(vals)]...))
end