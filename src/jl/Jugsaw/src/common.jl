# Ref: https://github.com/JuliaLang/julia/blob/master/stdlib/Distributed/src/messages.jl

Base.@kwdef struct ObjectRef
    object_id::String = string(uuid4())
end

struct Message
    request::JugsawFunctionCall
    response::ObjectRef
end
