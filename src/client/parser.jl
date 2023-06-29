# endpoint is the remote endpoint
function load_app(context::ClientContext, str::String)
    adt = JugsawIR.ir2adt(str)
    appadt, typesadt = adt.storage
    tt = JugsawIR.adt2julia(typesadt, JugsawIR.demoof(JugsawIR.TypeTable))
    return _load_app(context, appadt, tt)
end
function _load_app(context::ClientContext, obj::JugsawADT, tt::TypeTable)
    name, method_names, _method_demos = obj.fields
    method_demos = makeordereddict(_method_demos)
    demos = OrderedDict{Symbol, Vector{Demo}}()
    for _fname in method_names.fields[2].storage
        fname = Symbol(_fname)
        demos[fname] = Demo[]
        for demo in aslist(method_demos[_fname])
            (_fcall, result, meta) = demo.fields
            _fname, args, kwargs = _fcall.fields
            jf = Call(fname, (args.fields...,), (; zip(Symbol.(JugsawIR.get_fieldnames(kwargs, tt)), kwargs.fields)...))
            demo = Demo(jf, result, makedict(meta))
            push!(demos[fname], demo)
        end
    end
    app = App(Symbol(name), demos, tt, context)
    return app
end