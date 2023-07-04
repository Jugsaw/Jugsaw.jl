using Jugsaw

"""
    greet(x)

A function returns "Hello, \$x".
"""
greet(x::String) = "Hello, $x"

# test input types
@enum ENM X Y Z
const dict = Dict(3 => 5)

@register helloworld begin
    greet("Jinguo") == "Hello, Jinguo"
    identity((X, 1.0, 1, "string", nothing, [1, 2], dict, ComplexF64)) == (X, 1.0, 1, "string", nothing, [1, 2], dict, ComplexF64)
end