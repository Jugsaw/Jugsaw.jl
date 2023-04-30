struct JugsawTransformer <: Transformer end

@rule object(jt::JugsawTransformer, items) = items[]
@rule genericobj1(jt::JugsawTransformer, items) = begin
    d = dict(items)
    values = d["values"]
    fields = fieldnames(jt.demo)
    # fallback
    vals = Any[fromdict(m, T.types[i], values[i]) for i=1:length(fields) if isdefined(jt.demo, fn)]
    #generic_customized_parsetype(m, T, Tuple(values))
    Core.eval(m, Expr(:new, T, Any[:($vals[$i]) for i=1:length(vals)]...))
end
@rule list(jt::JugsawTransformer, items) = items
@rule number(jt::JugsawTransformer, items) = Meta.parse(items[].value)
@rule string(jt::JugsawTransformer, items) = Meta.parse(items[].value)
@rule true(jt::JugsawTransformer, items) = true
@rule false(jt::JugsawTransformer, items) = false
@rule null(jt::JugsawTransformer, items) = nothing

const jpt = Lark(read(joinpath(pkgdir(JugsawIR), "src", "jugsawir.lark"), String),parser="lalr",lexer="contextual", start="object", transformer=JugsawTransformer())

struct JugsawObj
    typename::String
    fields::Vector
    fieldnames::Vector
end
Base.show(io::IO, ::MIME"plain/text", obj::JugsawObj) = Base.show(io, obj)
function Base.show(io::IO, obj::JugsawObj)
    typename, fields, fieldnames = obj.typename, obj.fields, obj.fieldnames
    print(io, "$typename(")
    for (k, (fn, fv)) in enumerate(zip(fieldnames, fields))
        print(io, "$fn = $fv")
        if k!=length(fields)
            print(io, ", ")
        end
    end
    print(io, ")")
end

load_types_from_file(filename::String) = load_types(read(filename, String))
load_types(str::String) = JugsawIR.parse4(str, JugsawIR.demoof(TypeTable))

function load_demos_from_dir(dirname::String)
    types = load_types(read(joinpath(dirname, "types.json"), String))
    tdemos = Lerche.parse(JugsawIR.jp, read(joinpath(dirname, "demos.json"), String))
    return load_demos(tdemos, types)
end
function load_demos(t::Tree, types::TypeTable)
    @match t.data begin
        "object" || "number" || "string" => load_demos(t.children[], types)
        "true" => true
        "false" => false
        "null" => nothing
        "list" => load_demos.(t.children, Ref(types))
        "genericobj1" => error("type name not specified!")
        "genericobj2" => buildobj(load_demos(t.children[1], types), load_demos.(t.children[2].children, Ref(types)), types)
        "genericobj3" => buildobj(load_demos(t.children[2], types), load_demos.(t.children[1].children, Ref(types)), types)
    end
end
load_demos(t::Token, types::TypeTable) = Meta.parse(t.value)
function buildobj(typename, fields, types::TypeTable)
    fns, fts = types.defs[typename]
    return JugsawObj(typename, fields, fns)
end