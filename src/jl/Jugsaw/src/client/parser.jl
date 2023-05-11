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
    adt = JugsawIR.ir2adt(sdemos)
    appadt, typesadt = adt.storage
    return _load_app(tdemos, types)
end
function _load_app(t::Tree, types::TypeTable)
    obj = load_obj(t, types)
    name, method_sigs, method_demos = obj.fields
    demos = OrderedDict{Symbol, Vector{Pair{String, Demo}}}()
    for sig in method_sigs
        (_fcall, result, meta) = method_demos[sig].fields
        fcall, args, kwargs = _fcall.fields
        jf = Call(fcall.typename, args, (; zip(Symbol.(kwargs.fieldnames), kwargs.fields)...))
        demo = Demo(jf, result, meta)
        # document the demo
        fname = purename(Meta.parse(fcall.typename))
        if haskey(demos, fname)
            push!(demos[fname], _fcall.typename => demo)
        else
            demos[fname] = [_fcall.typename => demo]
        end
    end
    app = App(Symbol(name), demos, types)
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
function load_obj(t::Token, types::TypeTable)
    # wield parsing error when handling interpolated strings
    local res
    try
        res = Meta.parse(t.value)
    catch e
        Base.showerror(stdout, e)
        println(stdout)
        @info "try fixing! error str: $(t.value)"
        res = Meta.parse(replace(t.value, "\$"=>"\\\$"))
    end
    return res
end

function buildobj(typename, fields, types::TypeTable)
    fns, fts = types.defs[typename]
    rawname = purename(Meta.parse(typename))
    @match rawname begin
        :Array => reshape(fields[2], fields[1]...)
        :Dict => Dict(zip(fields[1], fields[2]))
        :Enum => error("I do not want to support it!")
        :Tuple => (fields...,)
        _ => JugsawObj(typename, fields, fns)
    end
end

function JugsawIR.construct_object(t::Lerche.Tree, demo::JugsawObj)
    # there may be a first field "type".
    flds = JugsawIR._getfields(t)
    vals = [JugsawIR.fromtree(val, demoval) for (val, demoval) in zip(flds, demo.fields)]
    JugsawObj(demo.typename, vals, demo.fieldnames)
end