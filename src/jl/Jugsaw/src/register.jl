# the application specification
struct AppSpecification
    name::String
    # `method_demo` is a mapping between function signatures and demos,
    # where a demo is a pair of jugsaw function call and result.
    method_demos::Dict
end
AppSpecification(name) = AppSpecification(name, Dict())
function Base.show(io::IO, app::AppSpecification)
    println(io, "AppSpecification: $(app.name)")
    println(io, "Method table = [")
    for (k, (sig, (demo, res))) in enumerate(app.method_demos)
        print(io, "  ")
        println(io, sig)
        print(io, "  - ")
        print(io, demo)
        println(io, " == $(repr(res))")
        k !== length(app.method_demos) && println(io)
    end
    print(io, "]")
end
Base.show(io::IO, ::MIME"text/plain", f::AppSpecification) = Base.show(io, f)

function register!(app::AppSpecification, f, args, kwargs)
    jf = JugsawFunctionCall(f, args, kwargs)
    sig = function_signature(jf)
    result = f(args...; kwargs...)
    if !haskey(app.method_demos, sig)
        app.method_demos[sig] = (jf=>result)
    end
    return result
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
            push!(exs, :($ret = $register!($app, $fname, ($(render_args.(Ref(app), args, Ref(exs))...),),
                (; $(render_kwargs.(Ref(app), kwargs, Ref(exs))...)))))
            ret
        end
        :($fname($(args...))) => begin
            ret = gensym("ret")
            push!(exs, :($ret = $register!($app, $fname, ($(render_args.(Ref(app), args, Ref(exs))...),), NamedTuple())))
            ret
        end
        :(begin $(body...) end) => begin
            register_by_expr.(Ref(app), body, Ref(exs))
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
