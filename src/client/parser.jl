# endpoint is the remote endpoint
function load_app(context::ClientContext, str::String)
    adt = JugsawIR.ir2adt(str)
    appadt, typesadt = unpack_list(adt)
    tt = JugsawIR.adt2julia(typesadt, JugsawIR.demoof(JugsawIR.TypeTable))
    return _load_app(context, appadt, tt)
end
function _load_app(context::ClientContext, obj::JugsawExpr, tt::TypeTable)
    name, _method_names, _method_demos = unpack_fields(obj)
    _, method_names = unpack_fields(_method_names)
    method_demos = makeordereddict(_method_demos)
    demos = OrderedDict{Symbol, Demo}()
    for _fname in unpack_list(method_names)
        fname = Symbol(_fname)
        (_fcall, result, meta) = unpack_fields(method_demos[_fname])
        _fname, args, kwargs = unpack_call(_fcall)
        jf = Call(fname, (unpack_fields(args)...,), (; zip(Symbol.(JugsawIR.get_fieldnames(kwargs, tt)), unpack_fields(kwargs))...))
        demos[fname] = Demo(jf, result, makedict(meta))
    end
    app = App(Symbol(name), demos, tt, context)
    return app
end