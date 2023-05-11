# the application specification
struct AppSpecification
    name::Symbol
    # `method_demos` is a maps function names to demos,
    # where a demo is a pair of jugsaw function call and result.
    method_names::Vector{String}
    method_demos::Dict{String, Vector{JugsawDemo}}
end
AppSpecification(name) = AppSpecification(name, String[], Dict{String,JugsawDemo}())
function nfunctions(app::AppSpecification)
    @assert length(app.method_names) == length(app.method_demos)
    return length(app.method_names)
end
Base.:(==)(app::AppSpecification, app2::AppSpecification) = app.name == app2.name && app.method_demos == app.method_demos && app.method_names == app.method_names
function Base.show(io::IO, app::AppSpecification)
    println(io, "AppSpecification: $(app.name)")
    println(io, "Method table = [")
    for (k, (fname, demos)) in enumerate(app.method_demos)
        print(io, "- ")
        println(io, fname)
        for (l, demo) in enumerate(demos)
            print(io, "  - ")
            println(io, demo)
            (k !== length(app.method_demos) || l !== length(demos)) && println(io)
        end
    end
    print(io, "]")
end
Base.show(io::IO, ::MIME"text/plain", f::AppSpecification) = Base.show(io, f)
function Base.empty!(app::AppSpecification)
    empty!(app.method_names)
    empty!(app.method_demos)
    return app
end

##### TypeAsFunction
# Protect type function with a wrapper, to prevent it being rendered as `DataType`.
# struct TypeAsFunction{T} end
# protect_type(::Type{T}) where T = TypeAsFunction{T}()
# protect_type(x) = x
# (::TypeAsFunction{T})(args...; kwargs...) where T = T(args...; kwargs...)

function register!(app::AppSpecification, f, args::Tuple, kwargs::NamedTuple)
    #f = protect_type(_f)
    jf = Call(f, args, kwargs)
    fname = JugsawIR.safe_f2str(f)
    result = f(args...; kwargs...)
    # if the function is not yet registered, add a new method
    if !haskey(app.method_demos, fname)
        push!(app.method_names, fname)
        app.method_demos[fname] = JugsawDemo[]
    end
    # create a new demo
    doc = string(Base.Docs.doc(Base.Docs.Binding(module_and_symbol(f)...)))
    push!(app.method_demos[fname], JugsawDemo(jf, result, Dict{String,Any}("docstring"=>doc)))
    return result
end
module_and_symbol(f::DataType) = f.name.module, f.name.name
module_and_symbol(f::Function) = typeof(f).name.module, Symbol(f)
module_and_symbol(f::UnionAll) = module_and_symbol(f.body)
#module_and_symbol(::TypeAsFunction{T}) where T = module_and_symbol(T)
module_and_symbol(::Type{T}) where T = module_and_symbol(T)

macro register(app, ex)
    reg_statements = []
    register_by_expr(app, ex, reg_statements)
    return esc(:($(reg_statements...); $app))
end

function register_by_expr(app, ex, exs)
    @match ex begin
        :($a == $b) => begin
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
            if fname in [:(==), :(≈)]
                # these are for tests
                :(@assert $fname($(render_args.(Ref(app), args, Ref(exs))...)))
            else
                ret = gensym("ret")
                push!(exs, :($ret = $register!($app, $fname, ($(render_args.(Ref(app), args, Ref(exs))...),), NamedTuple())))
                ret
            end
        end
        :(begin $(body...) end) => begin
            register_by_expr.(Ref(app), body, Ref(exs))
        end 
        ::LineNumberNode => nothing
        _ => (@warn("not handled expression: $ex"); ex)
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
