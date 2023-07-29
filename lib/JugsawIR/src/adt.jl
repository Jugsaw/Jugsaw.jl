# JugsawIR code -> Lerche.Tree -> JugsawExpr <-> Julia
#       ↑                            ↓
#       <-----------------------------

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
function get_fieldnames(obj::JugsawExpr, tt::TypeTable)
    @assert obj.head == :object
    return tt.defs[obj.args[1]].fieldnames
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

# data are dumped to (name, value[, fieldnames])
function julia2adt!(@nospecialize(x::T), tt::TypeTable) where T
    @match x begin
        ###################### Basic Types ######################
        ::UndefInitializer => nothing
        ::DirectlyRepresentableTypes => x
        ::Function => string(x)
        ::UnionAll => type2str(x)
        ::Call => JugsawExpr(:call, [julia2adt!(x.fname, tt), julia2adt!(x.args, tt), julia2adt!(x.kwargs, tt)])
        ::Storage => JugsawExpr(:list, julia2adt!.(x.storage, Ref(tt)))
        ###################### Generic Compsite Types ######################
        _ => begin
            _x = native2jugsaw(x)
            Tx = typeof(_x)
            (_x isa UndefInitializer || _x isa DirectlyRepresentableTypes) || pushtype!(tt, Tx)
            JugsawExpr(:object, Any[type2str(Tx), 
                Any[isdefined(_x, fn) ? julia2adt!(getfield(_x, fn), tt) : undef for fn in fieldnames(Tx)]...]
            )
        end
    end
end

###################### ADT to julia
function adt2julia(t, @nospecialize(demo::T)) where T
    @match demo begin
        ###################### Basic Types ######################
        ::Nothing || ::Missing || ::UndefInitializer || ::Type || ::Function => demo
        ::Char => T(t[1])
        ::DirectlyRepresentableTypes => T(t)
        # ::JugsawExpr => t
        ::Storage => begin
            @assert t.head == :list "expect the expression be a list, got: $(t.head)"
            T(adt2julia.(t.args, Ref(demoofelement(demo.storage))))
        end
        ::Call => begin
            @assert t.head == :call "expect the expression be a call, got: $(t.head)"
            fname, args, kwargs = t.args
            Call(demo.fname, adt2julia(args, demo.args), adt2julia(kwargs, demo.kwargs))
        end
        ###################### Generic Compsite Types ######################
        _ => begin
            _x = native2jugsaw(demo)
            fields = JugsawIR.unpack_fields(t)
            vals = [adt2julia(fields[i], getfield(_x, fn)) for (i, fn) in enumerate(fieldnames(typeof(_x))) if isdefined(_x, fn)]
            obj = Core.eval(@__MODULE__, Expr(:new, typeof(_x), Any[:($vals[$i]) for i=1:length(vals)]...))
            jugsaw2native(obj, demo)
        end
    end
end
