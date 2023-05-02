using Jugsaw

greet(x::String) = "Hello, $(x)!"

app = Jugsaw.AppSpecification(:helloworld)
@register app greet("Jugsaw")

#####

# Base.@kwdef mutable struct Counter
#     n::Int = 0
# end

# (c::Counter)(n::Int) = c.n += n

# @register app Counter(0)

#####

r = Jugsaw.AppRuntime(app)
serve(r, @__DIR__; is_async=false)