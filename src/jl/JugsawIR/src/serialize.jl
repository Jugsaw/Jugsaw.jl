# Extended JSON
# https://github.com/quinnj/JSON3.jl
# `julia2ir` parse an object to string, which can be used to
# 1. parse a Julia object to a json object, with complete type specification.
# 2. parse a function specification to a json object, with complete input argument specification.
# `ir2julia` is the inverse of `julia2ir`.

# the typed parsing
function julia2ir(obj)
    obj, type = julia2adt(obj)
    typed, typet = julia2adt(type)
    # TODO: remove json!
    JSON3.write(obj), JSON3.write(typed)
end
function def!(tt::TypeTable, type::String, fieldnames::Vector{String}, @nospecialize(fieldvalues::Tuple))
    if !haskey(tt.defs, type)
        push!(tt.names, type)
        tt.defs[type] = (fieldnames, [type2str(typeof(x)) for x in fieldvalues])
    end
    return Dict("type"=>type, "fields"=>collect(Any, fieldvalues))
end

# NOTE: at least one element is required to help Array and Dict to parse.
function tree2julia(t::Lerche.Tree, demo::T) where T
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
            reshape(eltype(T)[tree2julia(x, d) for x in storage.children[1].children], Int[tree2julia(s, 0) for s in size.children[1].children]...)
        end
        ::Enum => begin
            kind, value, options = _getfields(t)
            T(findfirst(==(Meta.parse(value.children[1].children[1].value)), [Meta.parse(o.children[1].children[1].value) for o in options.children[1].children])-1)
        end
        ::Tuple => begin
            ([tree2julia(v, d) for (v, d) in zip(_getfields(t), demo)]...,)
        end
        ::Dict => begin
            ks, vs = _getfields(t)
            kd, vd = length(demo) > 0 ? (first(keys(demo)), first(values(demo))) : (demoof(key_type(demo)), demoof(value_type(demo)))
            T(zip([tree2julia(k, kd) for k in ks.children[1].children],
              [tree2julia(v, vd) for v in vs.children[1].children]))
        end

        ###################### Generic Compsite Types ######################
        _ => begin
            nfields(demo) == 0 ? demo : construct_object(t, demo)
        end
    end
end
function construct_object(t::Lerche.Tree, demo::T) where T
    # there may be a first field "type".
    #t.children[end].children[1].children[i]
    flds = _getfields(t)
    vals = [tree2julia(flds[i], getfield(demo, fn)) for (i, fn) in enumerate(fieldnames(T)) if isdefined(demo, fn)]
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
        @assert data == "genericobj3" "got: $data"
        return Meta.parse(t.children[1].children[2].value)
    end
end

###################### Lark ########################
const jp = Lark(read(joinpath(@__DIR__, "jugsawir.lark"), String),parser="lalr",lexer="contextual", start="object")
ir2tree(str::String) = Lerche.parse(jp, str)
function ir2julia(str::String, demo)
    tree = ir2tree(str)
    adt = tree2adt(tree)
    return adt2julia(adt, demo)
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