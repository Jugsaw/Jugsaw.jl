struct Demo
    fcall::Call
    result
    meta::Dict{String}
end
Base.show(io::IO, ::MIME"text/plain", d::Demo) = Base.show(io, d)
function Base.show(io::IO, d::Demo)
    print(io, "$(d.fcall) = $(d.result)")
end
Base.Docs.doc(d::Demo) = Markdown.parse(get(d.meta, "docstring", ""))

# the application instance, potential issues: function names __name, __endpoint and __method_demos, __type_table may cause conflict.
struct App
    name::Symbol
    method_demos::OrderedDict{Symbol, Vector{Demo}}
    type_table::TypeTable
end
function Base.getproperty(app::App, fname::Symbol)
    res = app[:method_demos][fname]
    return res
end
Base.getindex(a::App, f::Symbol) = getfield(a, f)
Base.propertynames(app::App) = (keys(app[:method_demos])...,)
Base.show(io::IO, ::MIME"text/plain", d::App) = Base.show(io, d)
function Base.show(io::IO, app::App)
    println(io, "App: $(app[:name])")
    n = 0
    for (name, demos) in app[:method_demos]
        println(io, "  - $name")
        k = 0
        if length(demos) == 1
            println(io, "    $(demos[].result)")
            k += 1
        else
            for demo in demos
                println(io, "    $('a' + k): $(demo)")
                k += 1
            end
        end
        n += k
    end
    print(io, "$n method instance in total, check `type_table` field for type definitions.")
    #print(io, app.type_table)
end
# for printing docstring
Base.Docs.Binding(app::App, sym::Symbol) = getproperty(app, sym)[1]