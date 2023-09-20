# endpoint is the remote endpoint
function load_app(context::ClientContext, str::String)
    obj = JugsawIR.read_object(str)
    return _load_app(context, obj.app, obj.typespec)
end
function _load_app(context::ClientContext, app, tt)
    demos = OrderedDict{Symbol, Demo}()
    for _fname in app.method_names
        fname = Symbol(_fname)
        demo = app.method_demos[_fname]
        (fcall, result, meta) = demo.fcall, demo.result, demo.meta
        jf = Call(fname, (fcall.args...,), (; fcall.kwargs...))
        demos[fname] = Demo(jf, result, Dict([String(x)=>y for (x,y) in meta]))
    end
    app = App(Symbol(app.name), demos, tt, context)
    return app
end