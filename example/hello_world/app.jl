using Jugsaw

greet(x::String="Jugsaw") = "Hello, $(x)!"

@register greet

#####

Base.@kwdef mutable struct Counter
    n::Int = 0
end

(c::Counter)(n::Int) = c.n += n

@register Counter()

#####

serve()