# endpoint is the remote endpoint
function load_app(context::ClientContext, str::String)
    obj = JugsawIR.read_object(str)
    return _load_app(context, obj.app, obj.typespec)
end
function _load_app(context::ClientContext, app, tt)
    _, method_names = unpack_fields(app.method_names)
    method_demos = makeordereddict(app.method_demos)
    demos = OrderedDict{Symbol, Demo}()
    for _fname in unpack_list(method_names)
        fname = Symbol(_fname)
        (_fcall, result, meta) = unpack_fields(method_demos[_fname])
        _fname, args, kwargs = unpack_call(_fcall)
        jf = Call(fname, (unpack_fields(args)...,), (; zip(Symbol.(JugsawIR.get_fieldnames(kwargs, tt)), unpack_fields(kwargs))...))
        demos[fname] = Demo(jf, result, meta)
    end
    app = App(Symbol(app.name), demos, tt, context)
    return app
end