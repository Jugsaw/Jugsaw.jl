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

function load_app(str::String)
    tdemos, ttypes = JugsawIR.Lerche.parse(JugsawIR.jp, str).children[].children
    types = JugsawIR.fromtree(ttypes, JugsawIR.demoof(TypeTable))
    return _load_app(tdemos, types)
end
function _load_app(t::Tree, types::TypeTable)
    obj = load_obj(t, types)
    name, method_sigs, method_demos = obj.fields
    ks, vs = method_demos.fields
    demodict = Dict(zip(ks, vs))
    demos = OrderedDict{Symbol, Vector{Demo}}()
    for sig in method_sigs.fields[2]
        (fcall, result, meta) = demodict[sig].fields
        fcall, args, kwargs = fcall.fields
        jf = JugsawFunctionCall(fcall.typename, (args.fields...,), (; zip(kwargs.fields)...))
        demo = Demo(jf, result, Dict(zip(meta.fields...)))
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