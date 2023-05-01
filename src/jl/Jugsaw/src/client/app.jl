struct Demo
    fcall::JugsawFunctionCall
    result
    docstring::String
end
struct App
    name::Symbol
    endpoint::URI
    method_demos::OrderedDict{String, Demo}
    type_table::TypeTable
end

function App(appname::Symbol; endpoint="http://localhost:8081/actors/")
    uri = URI(endpoint)
    method_demos, type_table = request_method_demos(uri, appname)
    return App(appname, uri, method_demos, type_table)
end
function request_method_demos(endpoint::URI, appname::String)
    demo_url = joinpath(endpoint, "$appname", "demos")
    r = HTTP.post(demo_url, ["content-type" => "application/json"], req) # Deserialize
    tree = JugsawIR.Lerche.parse(JugsawIR.jp, String(r.body))
    return tree
end

function query_function()
end
function query_type()
end

struct ActorTypeRef
    app::App
    actor_type::String
end

struct ActorRef
    actor_type_ref::ActorTypeRef
    actor_id::String
end

Base.getproperty(a::App, name::Symbol) = ActorTypeRef(a, string(name))
Base.getindex(a::App, f::Symbol) = getfield(a, f)

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
