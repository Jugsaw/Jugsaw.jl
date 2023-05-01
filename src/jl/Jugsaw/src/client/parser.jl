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
    return load_app(tdemos, types)
end
function load_app(t::Tree, types::TypeTable)
    obj = load_obj(t, types)
    name, method_sigs, method_demos = obj.fields
    ks, vs = method_demos.fields
    demodict = Dict(zip(ks, vs))
    demos = OrderedDict{Symbol, Vector{Demo}}()
    for sig in method_sigs.fields[2]
        (fcall, result, docstring) = demodict[sig].fields
        fcall, args, kwargs = fcall.fields
        jf = JugsawFunctionCall(fcall.typename, (args.fields...,), (; zip(kwargs.fields)...))
        demo = Demo(jf, result, docstring)
        # document the demo
        fname = decode_fname(fcall.typename)
        if haskey(demos, fname)
            push!(demos[fname], demo)
        else
            demos[fname] = [demo]
        end
    end
    app = App(Symbol(name), demos, types)
    # Warning: this is hacky!!!!
    @eval Base.fieldnames(::Type{App}) = $((keys(app[:method_demos])...,))
    return app
end
function decode_fname(fname::AbstractString)
    m = match(r".*\.#?(.*)$", fname)
    m === nothing && error("function name not parsed successfully: $fname")
    return Symbol(m[1])
end

function load_obj(t::Tree, types::TypeTable)
    @match t.data begin
        "object" || "number" || "string" => load_obj(t.children[], types)
        "true" => true
        "false" => false
        "null" => nothing
        "list" => load_obj.(t.children, Ref(types))
        "genericobj1" => error("type name not specified!")
        "genericobj2" => buildobj(load_obj(t.children[1], types), load_obj.(t.children[2].children, Ref(types)), types)
        "genericobj3" => buildobj(load_obj(t.children[2], types), load_obj.(t.children[1].children, Ref(types)), types)
    end
end
load_obj(t::Token, types::TypeTable) = Meta.parse(t.value)
function buildobj(typename, fields, types::TypeTable)
    fns, fts = types.defs[typename]
    return JugsawObj(typename, fields, fns)
end

print_app(demos::App) = print_app(stdout, demos)
function print_app(io::IO, app::App)
    name, method_sigs, method_demos, type_table = app.name, app.method_demos, app.type_table
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