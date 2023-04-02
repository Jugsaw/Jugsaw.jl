# register by using case
struct AppSpecification
    name::String
    method_table::Vector{Any}
    method_demos::Vector{Pair{Any,Any}}
end
AppSpecification(name) = AppSpecification(name, Any[], Pair{Any, Any}[])

function register!(app, f, args, kwargs)
    result = f(args...; kwargs...)
    push!(app.method_table, JugsawFunctionSpec{typeof(args), typeof(kwargs), typeof(result)}(app.name, string(f)))
    push!(app.method_demos, JugsawFunctionCall(app.name, string(f), args, kwargs)=>result)
    return result
end