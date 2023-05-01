# Extended JSON
# https://github.com/quinnj/JSON3.jl
# `json4` parse an object to string, which can be used to
# 1. parse a Julia object to a json object, with complete type specification.
# 2. parse a function specification to a json object, with complete input argument specification.
# `parse4` is the inverse of `json4`.

# the typed parsing
function json4(obj)
    obj, type = todict(obj)
    typed, typet = todict(type)
    # TODO: remove json!
    JSON3.write(obj), JSON3.write(typed)
end
struct TypeTable
    names::Vector{String}
    defs::Dict{String, Tuple{Vector{String}, Vector{String}}}
end
TypeTable() = TypeTable(String[], Dict{String, Tuple{Vector{String}, Vector{String}}}())
Base.show(io::IO, ::MIME"text/plain", t::TypeTable) = Base.show(io, t)
function Base.show(io::IO, t::TypeTable)
    println(io, "TypeTable")
    for (k, typename) in enumerate(t.names)
        println(io, "  - $typename")
        fns, fts = t.defs[typename]
        for (l, (fn, ft)) in enumerate(zip(fns, fts))
            print(io, "    - $fn::$ft")
            if !(k == length(t.names) && l == length(fns))
                println()
            end
        end
    end
end

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
        ::UndefInitializer => nothing
        ::DirectlyRepresentableTypes => x
        ##################### Specified Types ####################
        ::DataType => begin
            def!(tt, "Core.DataType", ["name", "fieldnames", "fieldtypes"], (type2str(String), type2str(Vector{String}), type2str(Vector{String})))
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

# NOTE: at least one element is required to help Array and Dict to parse.
function fromtree(t::Lerche.Tree, demo::T) where T
    @match demo begin
        ###################### Basic Types ######################
        ::Nothing || ::Missing || ::UndefInitializer => demo
        ::Bool => Meta.parse(t.children[1].data)
        ::Char => Meta.parse(t.children[1].children[1].value)[1]
        ::DirectlyRepresentableTypes => T(Meta.parse(t.children[1].children[1].value))

        ##################### Specified Types ####################
        ::Type || ::Function => demo
        ::Array => begin
            size, storage = _getfields(t)
            d = length(demo) > 0 ? first(demo) : demoof(eltype(demo))
            reshape(eltype(T)[fromtree(x, d) for x in storage.children[1].children], Int[fromtree(s, 0) for s in size.children[1].children]...)
        end
        ::Enum => begin
            kind, value, options = _getfields(t)
            T(findfirst(==(Meta.parse(value.children[1].children[1].value)), [Meta.parse(o.children[1].children[1].value) for o in options.children[1].children])-1)
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
demoof(::Type{T}) where T<:Tuple = (demoof.(T.parameters)...,)
demoof(::Type{T}) where {E,N,T<:AbstractArray{E,N}} = T(reshape([demoof(E)], ones(Int, N)...))
function demoof(::Type{T}) where T
    vals = demoof.(T.types)
    return Core.eval(@__MODULE__, Expr(:new, T, Any[:($vals[$i]) for i=1:length(vals)]...))
end

function construct_object(t::Lerche.Tree, demo::T) where T
    # there may be a first field "type".
    #t.children[end].children[1].children[i]
    flds = _getfields(t)
    vals = [fromtree(flds[i], getfield(demo, fn)) for (i, fn) in enumerate(fieldnames(T)) if isdefined(demo, fn)]
    return Core.eval(@__MODULE__, Expr(:new, T, Any[:($vals[$i]) for i=1:length(vals)]...))
end
function _getfields(t::Lerche.Tree)
    @assert t.data == "object"
    t1 = t.children[1]
    data = t1.data
    if data == "genericobj1"
        return t1.children[1].children
    elseif data == "genericobj2"
        return t1.children[2].children
    else
        @assert data == "genericobj3"
        return t1.children[1].children
    end
end
function _gettype(t::Lerche.Tree)
    @assert t.data == "object"
    data = t.children[1].data
    if data == "genericobj1"
        error("type is not specified!")
    elseif data == "genericobj2"
        return Meta.parse(t.children[1].children[1].value)
    else
        @assert data == "genericobj3"
        return Meta.parse(t.children[1].children[2].value)
    end
end

###################### Lark ########################
const jp = Lark(read(joinpath(@__DIR__, "jugsawir.lark"), String),parser="lalr",lexer="contextual", start="object")
function parse4(str::String, demo)
    tree = Lerche.parse(jp, str)
    fromtree(tree, demo)
end

AbstractTrees.children(t::Lerche.Tree) = t.children
function AbstractTrees.printnode(io::IO, t::Lerche.Tree)
	print(io, t.data)
end
function AbstractTrees.printnode(io::IO, t::Lerche.Token)
    print(io, t.value)
end

print_clean_tree(t::Lerche.Tree; kwargs...) = print_clean_tree(stdout, t; kwargs...)
function print_clean_tree(io::IO, t::Lerche.Tree; kwargs...)
    AbstractTrees.print_tree(io, cleanup(t); kwargs...)
end
function cleanup(tree::Lerche.Tree)
    if tree.data == "object"
        return cleanup(tree.children[1])
    else
        return Tree(tree.data, cleanup.(tree.children), tree._meta)
    end
end
cleanup(t::Lerche.Token) = t