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
    struct Vector
        storage::Vector
    end
end
Base.:(==)(a::JugsawADT, b::JugsawADT) = all(fn->getfield(a, fn) == getfield(b, fn), fieldnames(JugsawADT))
Base.show(io::IO, ::MIME"text/plain", a::JugsawADT) = Base.show(io, a)
# function Base.show(io::IO, a::JugsawADT)
#     @match a begin
#         JugsawADT.Object(typename, fields) => print(io, "$typename($(join(fields, ", ")))")
#         JugsawADT.Vector(storage) => print(io, storage)
#     end
# end

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
        if !haskey(t.defs, typename)
            println(io, "    - not exist")
            continue
        end
        type = t.defs[typename]
        fns, fts = fieldnames(type), type.types
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
function julia2adt!(@nospecialize(_x::T), tt::TypeTable) where T
    x = native2jugsaw(_x)
    Tx = typeof(x)
    (x isa UndefInitializer || x isa DirectlyRepresentableTypes) && pushtype!(tt, Tx)
    @match x begin
        ###################### Basic Types ######################
        ::UndefInitializer => nothing
        ::DirectlyRepresentableTypes => x
        ::Vector => JugsawADT.Vector(julia2adt!.(x, Ref(tt)))
        ::Function => f2str(x)
        ###################### Generic Compsite Types ######################
        _ => begin
            JugsawADT.Object(type2str(Tx), 
                Any[isdefined(x, fn) ? julia2adt!(getfield(x, fn), tt) : undef for fn in fieldnames(Tx)]
            )
        end
    end
end
f2str(f::Function) = "$(typeof(f).name.module).$(Symbol(f))"
f2str(::Type{T}) where T = type2str(T)

###################### ADT to julia
function adt2julia(t, demo::T) where T
    @match demo begin
        ###################### Basic Types ######################
        ::Nothing || ::Missing || ::UndefInitializer || ::Type || ::Function => demo
        ::Char => T(t[1])
        ::DirectlyRepresentableTypes => T(t)
        ::Vector => T(adt2julia.(t.storage, Ref(demoofarray(demo))))
        ###################### Generic Compsite Types ######################
        _ => begin
            construct_object(t, demo)
        end
    end
end
demoofarray(demo::Array) = length(demo) > 0 ? first(demo) : demoof(eltype(demo))

function construct_object(t::JugsawADT, demo::T) where T
    flds = t.fields
    vals = [adt2julia(flds[i], getfield(demo, fn)) for (i, fn) in enumerate(fieldnames(T)) if isdefined(demo, fn)]
    return Core.eval(@__MODULE__, Expr(:new, T, Any[:($vals[$i]) for i=1:length(vals)]...))
end