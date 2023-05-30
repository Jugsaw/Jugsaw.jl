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
            print(io, demo)
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

function selftest(app::AppSpecification)
    detail = Dict{String, Vector{Bool}}()
    res = true
    for func in app.method_names
        detail[func] = Bool[selftest(demo) for demo in app.method_demos[func]]
        res = res & all(detail[func])
    end
    return res, detail
end
function selftest(demo::JugsawDemo)
    res = fevalself(demo.fcall)
    return res === demo.result || res == demo.result || res ≈ demo.result
end

function register!(app::AppSpecification, f, args::Tuple, kwargs::NamedTuple, endpoint = get(ENV, "endpoint", "http://localhost:8088"))
    #f = protect_type(_f)
    jf = Call(f, args, kwargs)
    adt = JugsawIR.julia2adt(jf)[1]
    fname = safe_f2str(f)
    result = f(args...; kwargs...)
    # if the function is not yet registered, add a new method
    if !haskey(app.method_demos, fname)
        push!(app.method_names, fname)
        app.method_demos[fname] = JugsawDemo[]
    end
    # function signature not yet registered
    if match_demo(fname, args, kwargs, app) === nothing
        # create a new demo
        doc = string(Base.Docs.doc(Base.Docs.Binding(module_and_symbol(f)...)))
        push!(app.method_demos[fname], JugsawDemo(jf, result,
            Dict{String,String}(
                "docstring"=>doc,
                "args_type"=>JugsawIR.type2str(typeof(args)),
                "kwargs_type"=>JugsawIR.type2str(typeof(kwargs)),
                "api_julialang"=>generate_code(JuliaLang(), endpoint, app.name, adt, jf),
                "api_python"=>generate_code(Python(), endpoint, app.name, adt, jf),
                "api_javascript"=>generate_code(Javascript(), endpoint, app.name, adt, jf)
            )))
    end
    return result
end
function match_demo(fname::String, args, kwargs, app::AppSpecification)
    # handle function request error
    if !haskey(app.method_demos, fname) || isempty(app.method_demos[fname])
        return nothing
    end
    for demo in app.method_demos[fname]
        _, dargs, dkwargs = demo.fcall.fname, demo.fcall.args, demo.fcall.kwargs
        if typeof(dargs) == typeof(args) && typeof(dkwargs) == typeof(kwargs)
            return demo
        end
    end
    return nothing
end
module_and_symbol(f::DataType) = f.name.module, f.name.name
module_and_symbol(f::Function) = typeof(f).name.module, Symbol(f)
module_and_symbol(f::UnionAll) = module_and_symbol(f.body)
module_and_symbol(::Type{T}) where T = module_and_symbol(T)
function safe_f2str(f)
    sf = string(f)
    '.' ∈ sf && throw("function must be imported to the `Main` module before it can be exposed!")
    return sf
end

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
        _ => (@warn("not handled expression: $(repr(ex))"); ex)
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

####################### Save load demos to disk
# save demos to the disk
function save_demos(dir::String, methods::AppSpecification)
    mkpath(dir)
    demos, types = JugsawIR.julia2ir(methods)
    fdemos = joinpath(dir, "demos.json")
    @info "dumping demos to: $fdemos"
    open(fdemos, "w") do f
        write(f, "[$demos, $types]")
    end
end

# load demos from the disk
function load_demos_from_dir(dir::String, demos)
    sdemos = read(joinpath(dir, "demos.json"), String)
    return load_demos(sdemos, demos)
end
function load_demos(sdemos::String, demos)
    adt = JugsawIR.ir2adt(sdemos)
    appadt, typesadt = adt.storage
    return JugsawIR.adt2julia(appadt, demos), JugsawIR.adt2julia(typesadt, JugsawIR.demoof(JugsawIR.TypeTable))
end

