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
end
Base.:(==)(a::JugsawADT, b::JugsawADT) = all(fn->getfield(a, fn) == getfield(b, fn), fieldnames(JugsawADT))
Base.show(io::IO, ::MIME"text/plain", a::JugsawADT) = Base.show(io, a)
function Base.show(io::IO, a::JugsawADT)
    @match a begin
        JugsawADT.Object(typename, fields) => print(io, "$typename($(join(fields, ", ")))")
        JugsawADT.Call(fname, args, kwargnames, kwargvalues) => print(io, "$fname($(join(repr.(args), ", ")); $(join(["$k=$(repr(v))" for (k, v) in zip(kwargnames, kwargvalues)], ", ")))")
        JugsawADT.Type(name, fieldnames, fieldtypes) => print(io, "$name($(join(["$n::$t" for (n, t) in zip(fieldnames, fieldtypes)], ", ")))")
    end
end

struct TypeTable
    names::Vector{String}
    defs::Dict{String, JugsawADT}
end
TypeTable() = TypeTable(String[], Dict{String, Tuple{Vector{String}, Vector{String}}}())
function pushtype!(tt::TypeTable, type::JugsawADT)
    if !haskey(tt.defs, type.name)
        push!(tt.names, type.name)
        tt.defs[type.name] = type
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

########################## Julia to ADT
# returns the object and type specification
function julia2adt(@nospecialize(x::T)) where T
    tt = TypeTable()
    res = julia2adt!(x, tt)
    # dump type table
    return res, JugsawADT[tt.defs[s] for s in tt.names]
end

# data are dumped to (name, value[, fieldnames])
function julia2adt!(@nospecialize(x::T), tt::TypeTable) where T
    sT = type2str(T)
    @match x begin
        ###################### Basic Types ######################
        ::UndefInitializer => nothing
        ::DirectlyRepresentableTypes => x
        ##################### Specified Types ####################
        ::DataType => begin
            def!(tt, "Core.DataType",
                ["name", "fieldnames", "fieldtypes"],
                Any[type2str(x), isabstracttype(x) ? String[] : collect(string.(fieldnames(x))), String[type2str(x) for x in x.types]])
        end
        ::Array => def!(tt, sT,
            ["size", "storage"],
            Any[collect(size(x)), map(x->julia2adt!(x, tt), vec(x))]
        )
        ::Enum => def!(tt, sT,
            ["kind", "value", "options"],
            Any["DataType", string(x), String[string(v) for v in instances(typeof(x))]],
        )
        ::Dict => begin
            def!(tt, sT,
                ["keys", "vals"],
                Any[[julia2adt!(k, tt) for k in keys(x)], [julia2adt!(v, tt) for v in values(x)]],
            )
        end
        ###################### Generic Compsite Types ######################
        _ => begin
            fns = fieldnames(T)
            def!(tt, sT,
                String[string(x) for x in fns],
                Any[isdefined(x, fn) ? julia2adt!(getfield(x, fn), tt) : nothing for fn in fns],
            )
        end
    end
end
function def!(tt::TypeTable, typename::String, fieldnames::Vector{String}, fieldvalues::Vector{Any})
    pushtype!(tt, JugsawADT.Type(typename, fieldnames, String[type2str(typeof(x)) for x in fieldvalues]))
    return JugsawADT.Object(typename, fieldvalues)
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
            size, storage = t.fields
            d = length(demo) > 0 ? first(demo) : demoof(eltype(demo))
            reshape(eltype(T)[adt2julia(x, d) for x in storage], Int[adt2julia(s, 0) for s in size]...)
        end
        ::Enum => begin
            kind, value, options = t.fields
            T(findfirst(==(value), options)-1)
        end
        ::Tuple => begin
            ([adt2julia(v, d) for (v, d) in zip(t.fields, demo)]...,)
        end
        ::Dict => begin
            ks, vs = t.fields
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