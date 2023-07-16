"""
$(TYPEDEF)

### Fields
$(TYPEDFIELDS)
"""
Base.@kwdef mutable struct ClientContext
    endpoint::String = "http://localhost:8088/"
    localurl::Bool = false

    project::String = "unspecified"
    appname::Symbol = :unspecified
    version::String = "1.0"
end
Base.copy(c::ClientContext) = ClientContext(c.endpoint, c.localurl, c.project, c.appname, c.version)

"""
$(TYPEDEF)

### Fields
$(TYPEDFIELDS)
"""
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

"""
$(TYPEDEF)

### Fields
$(TYPEDFIELDS)
"""
struct DemoRef
    demo::Demo
    context::ClientContext
end
Base.show(io::IO, ::MIME"text/plain", d::DemoRef) = Base.show(io, d)
function Base.show(io::IO, ref::DemoRef)
    demo, context = ref.demo, ref.context
    println(io, demo)
    print(io, "context = $context")
end
Base.Docs.doc(d::DemoRef) = Base.Docs.doc(d.demo)
function (demo::DemoRef)(args...; kwargs...)
    call(demo.context, demo.demo, args...; kwargs...)
end
function run_demo(demo::DemoRef)
    call(demo.context, demo.demo, demo.demo.fcall.args...; demo.demo.fcall.kwargs...)
end
function test_demo(demo::DemoRef)
    result, expect = run_demo(demo)(), demo.demo.result
    return expect === result || result == expect || result ≈ expect
end

"""
$(TYPEDEF)

The Jugsaw application instance.

!!! note
    The `Base.getproperty` function has been overloaded to favor fetching demos. To get fields, please use `app[fieldname]`.
    For example, to get the application name, one should use `app[:name]`.

### Fields
$(TYPEDFIELDS)
"""
struct App
    name::Symbol
    method_demos::OrderedDict{Symbol, Demo}
    type_table::TypeTable
    context::ClientContext
end
function Base.getproperty(app::App, fname::Symbol)
    context = copy(app[:context])
    context.appname = app[:name]
    res = DemoRef(app[:method_demos][fname], context)
    return res
end
Base.getindex(a::App, f::Symbol) = getfield(a, f)
Base.propertynames(app::App) = (keys(app[:method_demos])...,)
Base.show(io::IO, ::MIME"text/plain", d::App) = Base.show(io, d)
function Base.show(io::IO, app::App)
    println(io, "App: $(app[:name])")
    for (name, demo) in app[:method_demos]
        println(io, "- ", demo)
    end
    print(io, "$(length(app[:method_demos])) methods in total, check the `type_table` field for type definitions.")
    #print(io, app.type_table)
end
# for printing docstring
Base.Docs.Binding(app::App, sym::Symbol) = getproperty(app, sym)
test_demo(app::App) = all(name->test_demo(getproperty(app, name)), propertynames(app))

##### Utilities
function makedict(adt::JugsawADT)
    pairs = aslist(adt.fields[1])
    return Dict([pair.fields[1]=>pair.fields[2] for pair in pairs])
end
function makeordereddict(adt::JugsawADT)
    pairs = aslist(adt.fields[1])
    return OrderedDict([pair.fields[1]=>pair.fields[2] for pair in pairs])
end
aslist(x::JugsawADT) = x.fields[2].storage