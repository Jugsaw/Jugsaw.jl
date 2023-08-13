using Jugsaw

"""
    greet(x)

A function returns "Hello, \$x".
"""
greet(x::String) = "Hello, $x"

# test input types
const dict = Dict(3 => 5)

@register helloworld begin
    greet("Jinguo") == "Hello, Jinguo"
    identity((1.0, 1, "string", nothing, [1, 2], dict, ComplexF64)) == (1.0, 1, "string", nothing, [1, 2], dict, ComplexF64)
end