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

struct DemoRef
    demo::Demo
    uri::URI
end
Base.show(io::IO, ::MIME"text/plain", d::DemoRef) = Base.show(io, d)
function Base.show(io::IO, ref::DemoRef)
    demo, uri = ref.demo, ref.uri
    println(io, demo)
    print(io, "remote = $uri")
end
#Base.Docs.doc(d::DemoRef) = Base.Docs.doc(d.demo)
function (demo::DemoRef)(args...; kwargs...)
    call(demo, args...; kwargs...)()
end
function run_demo(demo::DemoRef)
    call(demo, demo.demo.fcall.args...; demo.demo.fcall.kwargs...)()
end
function test_demo(demo::DemoRef)
    result, expect = run_demo(demo), demo.demo.result
    return expect === result || result == expect || result ≈ expect
end

struct DemoRefs
    name::Symbol
    demos::Vector{Demo}
    uri::URI
end
Base.show(io::IO, ::MIME"text/plain", d::DemoRefs) = Base.show(io, d)
function Base.show(io::IO, ref::DemoRefs)
    name, demos, uri = ref.name, ref.demos, ref.uri
    print_demos(io, name, demos)
    println()
    print(io, "remote = $uri")
end
function print_demos(io::IO, name, demos::Vector{Demo}, prefix="")
    println(io, prefix, "- $name")
    if length(demos) == 1
        print(io, prefix, "  $(demos[])")
    else
        k = 0
        for demo in demos
            print(io, prefix, "  $('a' + k): $(demo)")
            k += 1
            k != length(demos) && println(io)
        end
    end
end
Base.getindex(refs::DemoRefs, i::Int) = DemoRef(getindex(refs.demos, i), refs.uri)
Base.length(refs::DemoRefs) = length(refs.demos)
Base.iterate(refs::DemoRefs, state=1) = state <= length(refs.demos) ? (refs[state], state+1) : nothing
function (refs::DemoRefs)(args...; kwargs...)
    if length(refs.demos) == 1
        return refs[1](args...; kwargs...)
    else
        error("multiple ($(length(refs.demos))) method instance are defined for function `$(refs.name)`, please index the method explicitly with e.g. `demos[1](args..., kwargs...)` instead.")
    end
end
test_demo(demos::DemoRefs) = all(test_demo, demos)
#Base.Docs.doc(d::DemoRefs) = Base.Docs.doc(d.demos |> first)

# the application instance, potential issues: function names __name, __endpoint and __method_demos, __type_table may cause conflict.
struct App
    name::Symbol
    method_demos::OrderedDict{Symbol, Vector{Demo}}
    type_table::TypeTable
    uri::URI
end
function Base.getproperty(app::App, fname::Symbol)
    uri = app[:uri].scheme == "file" ? app[:uri] : joinpath(app[:uri], "actors", "$(app[:name]).$(fname)")
    res = DemoRefs(fname, app[:method_demos][fname], uri)
    return res
end
Base.getindex(a::App, f::Symbol) = getfield(a, f)
Base.propertynames(app::App) = (keys(app[:method_demos])...,)
Base.show(io::IO, ::MIME"text/plain", d::App) = Base.show(io, d)
function Base.show(io::IO, app::App)
    println(io, "App: $(app[:name])")
    for (name, demos) in app[:method_demos]
        print_demos(io, name, demos, "  ")
        println(io)
    end
    print(io, "$(length(app[:method_demos])) methods in total, check the `type_table` field for type definitions.")
    #print(io, app.type_table)
end
# for printing docstring
Base.Docs.Binding(app::App, sym::Symbol) = getproperty(app, sym)[1]
test_demo(app::App) = all(name->test_demo(getproperty(app, name)), propertynames(app))