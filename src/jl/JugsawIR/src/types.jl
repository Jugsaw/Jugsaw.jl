struct JugsawFunctionCall
    fname::F
    args::Vector
    kwargs::Vector{Pair{String, Any}}
end

function same_signature(a::JugsawFunctionCall{F1, argsT1, kwargsT1}, b::JugsawFunctionCall{F2, argsT2, kwargsT2}) where {F1, F2, argsT1, kwargsT1, argsT2, kwargsT2}
    return a.fname == b.fname && argsT1 === argsT2 && kwargsT1 === kwargsT2
end

feval(f::JugsawFunctionCall, args...; kwargs...) = f.fname(args...; kwargs...)
# evaluate nested function call
fevalself(x) = x
fevalself(f::JugsawFunctionCall) = feval(f, map(fevalself, f.args)...; map(fevalself, f.kwargs)...)
fevalself(f::Pair) = f.first=>fevalself(f.second)

# return a string as the function signature
function function_signature(f::JugsawFunctionCall)
    return JugsawIR.type2str(typeof(f))
end

function Base.show(io::IO, f::JugsawFunctionCall)
    kwargs = join(["$k=$(repr(v))" for (k, v) in zip(keys(f.kwargs), f.kwargs)], ", ")
    args = join([repr(v) for v in f.args], ", ")
    print(io, "$(f.fname)($args; $kwargs)")
end
Base.show(io::IO, ::MIME"text/plain", f::JugsawFunctionCall) = Base.show(io, f)

struct JugsawDemo
    fcall::JugsawFunctionCall
    result
    meta::Dict{String}
end
Base.:(==)(d1::JugsawDemo, d2::JugsawDemo) = d1.fcall == d2.fcall && d1.result == d2.result && d1.meta == d2.meta

function Base.show(io::IO, demo::JugsawDemo)
    print(io, demo.fcall)
    print(io, " == $(repr(demo.result))")
end
ftest(demo::JugsawDemo) = fevalself(demo.fcall) == demo.result
