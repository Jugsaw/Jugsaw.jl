# JugsawIR code -> Lerche.Tree -> JugsawADT <-> Julia
#       ↑                            ↓
#       <-----------------------------

############ TypeTable
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
function get_fieldnames(obj::JugsawADT, tt::TypeTable)
    return tt.defs[obj.typename].fieldnames
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
        ::Array => begin
            Tx = JArray{eltype(x)}
            (x isa UndefInitializer || x isa DirectlyRepresentableTypes) || pushtype!(tt, Tx)
            # NOTE: array must be special treated.
            JugsawADT.Object(type2str(Tx),
                Any[JugsawADT.Vector(collect(size(x))),  # size
                    JugsawADT.Vector(julia2adt!.(vec(x), Ref(tt)))]  # storage
            )
        end
        ::Function => string(x)
        ::UnionAll => type2str(x)
        ###################### Generic Compsite Types ######################
        _ => begin
            _x = native2jugsaw(x)
            Tx = typeof(_x)
            (_x isa UndefInitializer || _x isa DirectlyRepresentableTypes) || pushtype!(tt, Tx)
            JugsawADT.Object(type2str(Tx), 
                Any[isdefined(_x, fn) ? julia2adt!(getfield(_x, fn), tt) : undef for fn in fieldnames(Tx)]
            )
        end
    end
end

###################### ADT to julia
function adt2julia(t, demo::T) where T
    @match demo begin
        ###################### Basic Types ######################
        ::Nothing || ::Missing || ::UndefInitializer || ::Type || ::Function => demo
        ::Char => T(t[1])
        ::DirectlyRepresentableTypes => T(t)
        ::Array => begin
            size, data = t.fields
            T(reshape(adt2julia.(data.storage, Ref(demoofelement(demo))), size.storage...))
        end
        ::JugsawADT => t
        ###################### Generic Compsite Types ######################
        _ => begin
            construct_object(t, demo)
        end
    end
end

function construct_object(t::JugsawADT, demo::T) where T
    flds = t.fields
    vals = [adt2julia(flds[i], getfield(demo, fn)) for (i, fn) in enumerate(fieldnames(T)) if isdefined(demo, fn)]
    return Core.eval(@__MODULE__, Expr(:new, T, Any[:($vals[$i]) for i=1:length(vals)]...))
end