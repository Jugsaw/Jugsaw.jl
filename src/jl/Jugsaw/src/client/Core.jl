struct Demo
    fcall::JugsawFunctionCall
    result
    docstring::String
end
Base.show(io::IO, ::MIME"text/plain", d::Demo) = Base.show(io, d)
function Base.show(io::IO, d::Demo)
    print(io, "$(d.fcall) = $(d.result)")
end
Base.Docs.doc(d::Demo) = Markdown.parse(d.docstring)

# the application instance, potential issues: function names __name, __endpoint and __method_demos, __type_table may cause conflict.
struct App
    name::Symbol
    method_demos::OrderedDict{Symbol, Vector{Demo}}
    type_table::TypeTable
end
function Base.getproperty(app::App, fname::Symbol)
    res = app[:method_demos][fname]
    length(res) > 1 && error("multiple function is not yet supported!")
    return res[]
end
Base.getindex(a::App, f::Symbol) = getfield(a, f)
Base.show(io::IO, ::MIME"text/plain", d::App) = Base.show(io, d)
function Base.show(io::IO, app::App)
    println(io, "App: $(app[:name])")
    n = 0
    for (name, demos) in app[:method_demos]
        println(io, "  - $name")
        for demo in demos
            n += 1
            println(io, "    - $demo")
        end
    end
    print(io, "$n method instance in total, check `type_table` field for type definitions.")
    #print(io, app.type_table)
end
# for printing docstring
Base.Docs.Binding(app::App, sym::Symbol) = getproperty(app, sym)

# print_app(demos::App) = print_app(stdout, demos)
# function print_app(io::IO, app::App)
#     name, method_sigs, method_demos, type_table = app.name, app.method_demos, app.type_table
#     println(io, "AppSpecification: $name")
#     demodict = Dict(zip(method_demos.fields...))
#     for fname in method_sigs.fields[2]
#         call, res = demodict[fname].fields
#         fname, args, kwargs = call.fields
#         kwstr = join(["$(repr(k))=$(repr(v))" for (k, v) in kwargs.fields], ", ")
#         argstr = join(["$(repr(v))" for v in args.fields], ", ")
#         println(io, "  - $(fname.typename)($argstr; $kwstr) == $(repr(res))")
#     end
# end