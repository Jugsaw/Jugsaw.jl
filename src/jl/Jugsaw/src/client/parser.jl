struct JugsawObj
    typename::String
    fields::Vector
    fieldnames::Vector
end
Base.:(==)(a::JugsawObj, b::JugsawObj) = a.typename == b.typename && a.fields == b.fields
Base.isapprox(a::JugsawObj, b::JugsawObj; kwargs...) = a.typename == b.typename && isapprox(a.fields, b.fields; kwargs...)
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
# function JugsawIR.todict!(x::JugsawObj, tt::TypeTable)
#     JugsawIR.def!(tt::TypeTable, x.typename, x.fieldnames, (JugsawIR.todict!.(x.fields, Ref(tt))...,))
# end

function load_app(str::String)
    adt = JugsawIR.ir2adt(str)
    appadt, typesadt = adt.storage
    tt = JugsawIR.adt2julia(typesadt, JugsawIR.demoof(JugsawIR.TypeTable))
    return _load_app(appadt, tt)
end
function _load_app(obj::JugsawADT, tt::TypeTable)
    name, method_names, _method_demos = obj.fields
    ks, vs = _method_demos.fields
    method_demos = Dict(zip(ks.storage, vs.storage))
    demos = OrderedDict{Symbol, Vector{Demo}}()
    for _fname in method_names.storage
        fname = Symbol(_fname)
        demos[fname] = Demo[]
        for demo in method_demos[_fname].storage
            (_fcall, result, meta) = demo.fields
            fname, args, kwargs = _fcall.fields
            jf = Call(fname, args, (; zip(Symbol.(get_fieldnames(kwargs, tt)), kwargs.fields)...))
            demo = Demo(jf, result, meta)
            push!(demos[fname], demo)
        end
    end
    app = App(Symbol(name), demos, tt)
    # Warning: this is hacky!!!!
    @eval Base.fieldnames(::Type{App}) = $((keys(app[:method_demos])...,))
    return app
end

function purename(ex)
    @match ex begin
        ::Symbol => ex
        :(Jugsaw.TypeAsFunction{$type}) => purename(type)
        :($type{$(args...)}) => purename(type)
        :($a.$b) => purename(b)
        _ => error(string(ex))
    end
end