using Jugsaw

greet(x::String="Jugsaw") = "Hello, $(x)!"

@register Jugsaw.ACTOR_FACTORY greet()
@register Jugsaw.ACTOR_FACTORY greet("Jun Tian")

#####

# Base.@kwdef mutable struct Counter
#     n::Int = 0
# end

# (c::Counter)(n::Int) = c.n += n

# @register Counter()

#####

serve(@__DIR__)