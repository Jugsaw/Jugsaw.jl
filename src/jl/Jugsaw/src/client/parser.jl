# uri is the remote uri
function load_app(str::String, uri::URI)
    adt = JugsawIR.ir2adt(str)
    appadt, typesadt = adt.storage
    tt = JugsawIR.adt2julia(typesadt, JugsawIR.demoof(JugsawIR.TypeTable))
    return _load_app(appadt, tt, uri::URI)
end
function _load_app(obj::JugsawADT, tt::TypeTable, uri::URI)
    name, method_names, _method_demos = obj.fields
    ks, vs = _method_demos.fields
    method_demos = Dict(zip(ks.storage, vs.storage))
    demos = OrderedDict{Symbol, Vector{Demo}}()
    for _fname in method_names.storage
        fname = Symbol(_fname)
        demos[fname] = Demo[]
        for demo in method_demos[_fname].storage
            (_fcall, result, meta) = demo.fields
            _fname, args, kwargs = _fcall.fields
            jf = Call(fname, (args.fields...,), (; zip(Symbol.(JugsawIR.get_fieldnames(kwargs, tt)), kwargs.fields)...))
            demo = Demo(jf, result, Dict(zip(meta.fields[1].storage, meta.fields[2].storage)))
            push!(demos[fname], demo)
        end
    end
    app = App(Symbol(name), demos, tt, uri)
    return app
end