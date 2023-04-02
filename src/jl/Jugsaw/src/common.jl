# Ref: https://github.com/JuliaLang/julia/blob/master/stdlib/Distributed/src/messages.jl
using UUIDs

struct CallMsg
    args::Tuple
    kwargs::NamedTuple
end

Base.@kwdef struct ObjectRef
    object_id::String = string(uuid4())
end

struct Message
    request::CallMsg
    response::ObjectRef
end
