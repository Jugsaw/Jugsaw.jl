struct Remote
    uri::URI
end
Remote() = Remote("http://localhost:8081/actors/")

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
function App(remote::Remote, appname::Symbol)
    method_demos, type_table = request_method_demos(remote.uri, appname)
    return App(appname, method_demos, type_table)
end
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

#Base.getproperty(a::App, name::Symbol) = ActorTypeRef(a, string(name))
function request_method_demos(endpoint::URI, appname::String)
    demo_url = joinpath(endpoint, "$appname", "demos")
    r = HTTP.post(demo_url, ["content-type" => "application/json"], req) # Deserialize
    tree = JugsawIR.Lerche.parse(JugsawIR.jp, String(r.body))
    return tree
end

struct ActorTypeRef
    app::App
    actor_type::String
end

struct ActorRef
    actor_type_ref::ActorTypeRef
    actor_id::String
end

Base.getindex(a::ActorTypeRef, id::String) = ActorRef(a, id)
(x::ActorTypeRef)(args...; kw...) = ActorRef(x, "0")(args...; kw...)

function (a::ActorRef)(args...; kw...)
    app_name = a.actor_type_ref.app[:name]
    actor_type = a.actor_type_ref.actor_type
    act_url = joinpath(a.actor_type_ref.app[:endpoint], "$app_name.$actor_type", a.actor_id, "method")
    fetch_url = joinpath(act_url, "fetch")
    req = JSON3.write(CallMsg(args, values(kw))) # Serialize

    r = HTTP.post(act_url, ["content-type" => "application/json"], req) # Deserialize
    res = HTTP.post(fetch_url, ["content-type" => "application/json"], r.body)
    JSON3.read(res.body)
end

#####
# Usage
#####

# helloworld = App("HelloWorld")
# helloworld.greet("abc")
# c = helloworld.Counter["123"]
# c(1)
# c(2)
# c(3)
