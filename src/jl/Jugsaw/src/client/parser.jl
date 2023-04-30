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
        print(io, "$fn = $(repr(fv))")
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

print_app(demos::JugsawObj) = print_app(stdout, demos)
function print_app(io::IO, demos::JugsawObj)
    name, method_sigs, method_demos = demos.fields
    println(io, "AppSpecification: $name")
    demodict = Dict(zip(method_demos.fields...))
    for fname in method_sigs.fields[2]
        call, res = demodict[fname].fields
        fname, args, kwargs = call.fields
        kwstr = join(["$(repr(k))=$(repr(v))" for (k, v) in kwargs.fields], ", ")
        argstr = join(["$(repr(v))" for v in args.fields], ", ")
        println(io, "  - $(fname.typename)($argstr; $kwstr) == $(repr(res))")
    end
end