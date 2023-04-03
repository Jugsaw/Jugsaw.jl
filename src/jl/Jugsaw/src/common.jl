# Ref: https://github.com/JuliaLang/julia/blob/master/stdlib/Distributed/src/messages.jl
using UUIDs

struct JugsawFunctionCall{F, argsT<:Tuple, kwargsT<:NamedTuple}
    fname::F
    args::argsT
    kwargs::kwargsT
end

function same_signature(a::JugsawFunctionCall{F1, argsT1, kwargsT1}, b::JugsawFunctionCall{F2, argsT2, kwargsT2}) where {F1, F2, argsT1, kwargsT1, argsT2, kwargsT2}
    return a.fname == b.fname && argsT1 === argsT2 && kwargsT1 === kwargsT2
end

# return a string as the function signature
function function_signature(f::JugsawFunctionCall)
    return JugsawIR.type2str(typeof(f))
end

function Base.show(io::IO, f::JugsawFunctionCall)
    kwargs = join(["$k=$v" for (k, v) in zip(keys(f.kwargs), f.kwargs)], ", ")
    args = join(["$v" for v in f.args], ", ")
    print(io, "$(f.fname)($args; $kwargs)")
end
Base.show(io::IO, ::MIME"text/plain", f::JugsawFunctionCall) = Base.show(io, f)

Base.@kwdef struct ObjectRef
    object_id::String = string(uuid4())
end

struct Message
    request::JugsawFunctionCall
    response::ObjectRef
end
