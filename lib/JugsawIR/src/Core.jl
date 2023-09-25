# the docstring of a function and a type
module_and_symbol(f::DataType) = f.name.module, f.name.name
module_and_symbol(f::Function) = typeof(f).name.module, Symbol(f)
module_and_symbol(f::UnionAll) = module_and_symbol(f.body)
module_and_symbol(::Type{T}) where T = module_and_symbol(T)
description(x) = string(Base.Docs.doc(Base.Docs.Binding(module_and_symbol(x)...)))

################### Types ####################
# Call
"""
$(TYPEDEF)

### Fields
$(TYPEDFIELDS)
"""
struct Call{FT, argsT<:Tuple, kwargsT<:NamedTuple}
    fname::FT
    args::argsT
    kwargs::kwargsT
end
Base.:(==)(a::Call, b::Call) = a.fname == b.fname && a.args == b.args && a.kwargs == b.kwargs

feval(f::Call, args...; kwargs...) = f.fname(args...; kwargs...)
# evaluate nested function call
fevalself(x) = x
fevalself(f::Call) = feval(f, map(fevalself, f.args)...; update_kwargs(f.kwargs, map(fevalself, f.kwargs))...)
update_kwargs(::NamedTuple{K, V}, vals) where {K, V} = length(K) == 0 ? (;) : NamedTuple{K}((vals...,))

function Base.show(io::IO, f::Call)
    kwargs = join(["$k=$(repr(v))" for (k, v) in pairs(f.kwargs)], ", ")
    args = join([repr(v) for v in f.args], ", ")
    print(io, "$(f.fname)($args; $kwargs)")
end
Base.show(io::IO, ::MIME"text/plain", f::Call) = Base.show(io, f)

# JugsawDemo
struct JugsawDemo{CT<:Call, RT}
    fcall::CT
    result::RT
    meta::Dict{String, String}
end
Base.:(==)(d1::JugsawDemo, d2::JugsawDemo) = d1.fcall == d2.fcall && d1.result == d2.result && d1.meta == d2.meta

function Base.show(io::IO, demo::JugsawDemo)
    print(io, demo.fcall)
    print(io, " == $(repr(demo.result))")
end
ftest(demo::JugsawDemo) = fevalself(demo.fcall) == demo.result

#### errors
struct TypeTooAbstract <: Exception
    demo
end
function Base.showerror(io::IO, e::TypeTooAbstract, trace)
    print(io, "Type is too abstract, expect a more concrete one in a demo, got: $(e.demo) of type $(typeof(e.demo))")
end