export AppSpecification, JugsawFunctionCall, JugsawFunctionSpec, register!, registerT!, @register
# register by using case
struct AppSpecification
    name::String
    method_table::Vector{Any}
    method_demos::Vector{Pair{Any,Any}}
end
AppSpecification(name) = AppSpecification(name, Any[], Pair{Any, Any}[])
function Base.show(io::IO, app::AppSpecification)
    println(io, "AppSpecification: $(app.name)")
    println(io, "Method table = [")
    for (method, (demo, res)) in zip(app.method_table, app.method_demos)
        print(io, "  ")
        println(io, method)
        print(io, "  - ")
        print(io, demo)
        println(io, " == $res")
        println(io)
    end
    print(io, "]")
end
Base.show(io::IO, ::MIME"text/plain", f::AppSpecification) = Base.show(io, f)

function register!(app, f, args, kwargs)
    result = f(args...; kwargs...)
    funcspec = JugsawFunctionSpec{typeof(args), typeof(kwargs), typeof(result)}(app.name, string(f))
    if funcspec ∉ app.method_table
        push!(app.method_table, funcspec)
        push!(app.method_demos, JugsawFunctionCall(app.name, string(f), args, kwargs)=>result)
    end
    return result
end

# return the correct function for given function signature.
function find_method(demo, method_table)
    for (i, method_spec) in enumerate(method_table)
        if method_spec
        end
    end
end

using MLStyle
macro register(app, ex)
    reg_statements = []
    register_by_expr(app, ex, reg_statements)
    return esc(:($(reg_statements...); $app))
end

function register_by_expr(app, ex, exs)
    @match ex begin
        :($a = $b) => begin
            ra = register_by_expr(app, a, exs)
            rb = register_by_expr(app, b, exs)
            :(@assert $ra == $b)
        end
        :($a::$T) => begin
            ra = register_by_expr(app, a, exs)
            :(@assert $ra isa $T)  # return value is stored at the end!
        end
        :($fname($(args...); $(kwargs...))) => begin
            ret = gensym("ret")
            push!(exs, :($ret = $register!($app, $fname, ($(render_args.(app, args, Ref(exs))...),),
                (; $(render_kwargs.(app, kwargs, Ref(exs))...)))))
            ret
        end
        :($fname($(args...))) => begin
            ret = gensym("ret")
            push!(exs, :($ret = $register!($app, $fname, ($(render_args.(app, args, Ref(exs))...),), NamedTuple())))
            ret
        end
        :(begin $(body...) end) => begin
            register_by_expr.(app, body, Ref(exs))
        end 
        ::LineNumberNode => nothing
    end
end

function render_args(app, arg, exs)
    @match arg begin
        Expr(:call, fname, args...) => begin
            register_by_expr(app, arg, exs)
        end
        _ => arg
    end
end

function render_kwargs(app, kwarg, exs)
    @match kwarg begin
        Expr(:kw, name, value) => begin
            result = render_args(app, value, exs)
            Expr(:kw, getname(name), result)
        end
        ::Symbol => Expr(:kw, kwarg, kwarg)
        _ => error("keyword argument must be a symbol!")
    end
end

getname(ex) = @match ex begin
    ::Symbol => ex
    :($x::$T) => x
    _ => error("keyword argument must be a symbol!")
end
