# Extended JSON
# https://github.com/JuliaIO/JSON.jl
# `json4` parse an object to string, which can be used to
# 1. parse a Julia object to a json object, with complete type specification.
# 2. parse a function specification to a json object, with complete input argument specification.
# `parse4` is the inverse of `json4`.

# the typed parsing
function json4(obj)
    obj, type = todict(obj)
    typed, typet = todict(type)
    @show typet.names
    JSON.json(obj), JSON.json(typed)
end
struct TypeTable
    names::Vector{String}
    defs::Dict{String, Tuple{Vector{String}, Vector{String}}}
end
TypeTable() = TypeTable(String[], Dict{String, Tuple{Vector{String}, Vector{String}}}())

function def!(tt::TypeTable, type::String, fieldnames::Vector{String}, @nospecialize(fieldvalues::Tuple))
    if !haskey(tt.defs, type)
        push!(tt.names, type)
        tt.defs[type] = (fieldnames, [type2str(typeof(x)) for x in fieldvalues])
    end
    return Dict("type"=>type, "fields"=>collect(Any, fieldvalues))
end

# returns the object and type specification
function todict(@nospecialize(x::T)) where T
    tt = TypeTable()
    res = todict!(x, tt)
    return res, tt
end

# data are dumped to (name, value[, fieldnames])
function todict!(@nospecialize(x::T), tt::TypeTable) where T
    sT = type2str(T)
    @match x begin
        ###################### Basic Types ######################
        ::JSONTypes => x  # natively supported by JSON
        ::UndefInitializer => nothing
        ::Char || ::Int8 || ::Int16 || ::Int32 || ::Int128 ||    # extra types can be casted directly
            ::UInt8 || ::UInt16 || ::UInt32 || ::UInt128 ||
            ::Symbol || ::Missing || ::Float16 || ::Float32 => x
        #::UnionAll => type2str(x)
        #::Union => type2str(x)
        ##################### Specified Types ####################
        ::DataType => begin
            def!(tt, "DataType", ["name", "fieldnames", "fieldtypes"], (type2str(String), type2str(Vector{String}), type2str(Vector{String})))
        end
        ::Array => def!(tt, sT,
            ["size", "storage"],
            (collect(size(x)), map(x->todict!(x, tt), vec(x)))
        )
        ::Enum => def!(tt, sT,
            ["kind", "value", "options"],
            ("DataType", string(x), String[string(v) for v in instances(typeof(x))]),
        )
        ::Dict => begin
            def!(tt, sT,
                ["keys", "vals"],
                ([todict!(k, tt) for k in keys(x)], [todict!(v, tt) for v in values(x)]),
            )
        end
        ###################### Generic Compsite Types ######################
        _ => begin
            fns = fieldnames(T)
            def!(tt, sT,
                String[string(x) for x in fns],
                map(fn->isdefined(x, fn) ? todict!(getfield(x, fn), tt) : nothing, fns),
            )
        end
    end
end

function fromtree(t::Lerche.Tree, demo::T) where T
    @match demo begin
        ###################### Basic Types ######################
        ::Nothing || ::Missing || ::UndefInitializer => demo
        ::Bool => Meta.parse(t.children[1].data)
        ::Char => Meta.parse(t.children[1].value)[1]
        ::JSONTypes => Meta.parse(t.children[1].value)
        ::Char || ::Int8 || ::Int16 || ::Int32 || ::Int128 ||    # extra types can be casted directly
            ::UInt8 || ::UInt16 || ::UInt32 || ::UInt128 ||
            ::Symbol || ::Float16 || ::Float32 => T(Meta.parse(t.children[1].value))

        # NOTE: to get rid of type cast, we should use demo to deserialize an object.
        #::Type{UnionAll} => str2type(m, d)
        #::Type{Union} => str2type(m, d)
        ##################### Specified Types ####################
        ::Type => demo
        ::Array => begin
            size, storage = _getfields(t)
            d = length(demo) > 0 ? first(demo) : demoof(eltype(demo))
            reshape(eltype(T)[fromtree(x, d) for x in storage.children[1].children], Int[fromtree(s, 0) for s in size.children[1].children]...)
        end
        ::Enum => begin
            kind, value, options = _getfields(t)
            T(findfirst(==(Meta.parse(value.children[1].value)), [Meta.parse(o.children[1].value) for o in options.children[1].children])-1)
        end
        ::Tuple => begin
            ([fromtree(v, d) for (v, d) in zip(_getfields(t), demo)]...,)
        end
        ::Dict => begin
            ks, vs = _getfields(t)
            kd, vd = length(demo) > 0 ? (first(keys(demo)), first(values(demo))) : (demoof(key_type(demo)), demoof(value_type(demo)))
            T(zip([fromtree(k, kd) for k in ks.children[1].children],
              [fromtree(v, vd) for v in vs.children[1].children]))
        end

        ###################### Generic Compsite Types ######################
        _ => begin
            construct_object(t, demo)
        end
    end
end
demoof(::Type{T}) where T<:Number = zero(T)
demoof(::Type{T}) where T<:AbstractString = T("")
demoof(::Type{T}) where T<:Symbol = :x

function construct_object(t::Lerche.Tree, demo::T) where T
    # there may be a first field "type".
    vals = [fromtree(t.children[end].children[1].children[i], getfield(demo, fn)) for (i, fn) in enumerate(fieldnames(T)) if isdefined(demo, fn)]
    return Core.eval(@__MODULE__, Expr(:new, T, Any[:($vals[$i]) for i=1:length(vals)]...))
end
function _getfields(t::Lerche.Tree)
    if t.data == "genericobj1"
        return t.children[1].children[1].children
    elseif t.data == "genericobj2"
        return t.children[1].children[2].children
    else
        return t.children[1].children[1].children
    end
end

const jp = Lark(read(joinpath(@__DIR__, "jugsawir.lark"), String),parser="lalr",lexer="contextual", start="object")
function parse4(str::String, demo)
    tree = Lerche.parse(jp, str)
    fromtree(tree, demo)
end

using AbstractTrees
using AbstractTrees: print_tree
AbstractTrees.children(t::Lerche.Tree) = t.children
function AbstractTrees.printnode(io::IO, t::Lerche.Tree)
	print(io, t.data)
end
function AbstractTrees.printnode(io::IO, t::Lerche.Token)
    print(io, t.value)
end