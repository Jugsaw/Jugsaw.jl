abstract type AbstractLang end
struct JuliaLang <: AbstractLang end
struct Python <: AbstractLang end
struct Javascript <: AbstractLang end

# converting IR to different languages
function generate_code(::JuliaLang, endpoint::String, appname::Symbol, fcall::JugsawADT, democall::JugsawIR.Call)
    @assert fcall.typename == "JugsawIR.Call"
    if isempty(endpoint)
        error("The endpoint of this server is not set properly.")
    end
    callexpr = fexpr(JuliaLang(), fcall, democall)
    callexpr.args[1] = :(app.$(callexpr.args[1]))
    code = join(string.([
        :(using Jugsaw.Client),
        :(app = request_app(RemoteHandler($endpoint), $(QuoteNode(appname)))),
        callexpr
            ]), "\n")
    return string(code)
end

function fexpr(::JuliaLang, fcall, democall)
    fname, args, kwargs = fcall.fields
    return :($(fname)($([julia2client(JuliaLang(), arg, argdemo) for (arg, argdemo) in zip(args.fields, democall.args)]...);
        $([Expr(:kw, k, julia2client(JuliaLang(), v, vdemo)) for (k, v, vdemo) in zip(fieldnames(typeof(democall.kwargs)), kwargs.fields, democall.kwargs)]...)))
end


function julia2client(lang::AbstractLang, x, demo::T) where T
    @match demo begin
        ###################### Basic Types ######################
        ::Nothing || ::Missing || ::UndefInitializer || ::Type || ::Function => toexpr(lang, demo)
        ::Char => toexpr(lang, T(x[1]))
        ::JugsawIR.DirectlyRepresentableTypes => toexpr(lang, T(x))
        ::Vector => Expr(:vect, [julia2client(lang, elem, JugsawIR.demoofelement(demo)) for elem in x.storage]...)
        ::JugsawADT => error("what for?")
        ###################### Generic Compsite Types ######################
        _ => begin
            struct2expr(lang, x, demo)
        end
    end
end
toexpr(::JuliaLang, x) = :($x)
function struct2expr(lang::JuliaLang, t::JugsawADT, demo::T) where T
    vals = [julia2client(lang, field, getfield(demo, fn)) for (field, fn) in zip(t.fields, fieldnames(T)) if isdefined(demo, fn)]
    return :(($(vals...),))
end