abstract type AbstractLang end
struct JuliaLang <: AbstractLang end
struct Python <: AbstractLang end
struct Javascript <: AbstractLang end

function generate_code(::JuliaLang, endpoint::String, appname::Symbol, fcall::JugsawIR.Call)
    if isempty(endpoint)
        error("The endpoint of this server is not set properly.")
    end
    code = join(string.([
        :(using Jugsaw.Client),
        :(app = request_app(RemoteHandler($endpoint), $(QuoteNode(appname)))),
        :(app.$(fcall.fname)($(fcall.args...); $([Expr(:kw, k, v) for (k, v) in pairs(fcall.kwargs)]...))),
    ]), "\n")
    return string(code)
end