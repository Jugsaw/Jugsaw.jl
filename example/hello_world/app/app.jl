using Jugsaw

greet(x::String="Jugsaw") = "Hello, $(x)!"

app = Jugsaw.AppSpecification("helloworld")
@register app greet()

#####

Base.@kwdef mutable struct Counter
    n::Int = 0
end

(c::Counter)(n::Int=0) = c.n += n

@register app Counter()

#####

r = Jugsaw.AppRuntime(app)
serve(r, @__DIR__)