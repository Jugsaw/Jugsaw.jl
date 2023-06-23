using Jugsaw

"""
    greet(x)

A function returns "Hello, \$x".
"""
greet(x::String) = "Hello, $x"

app = AppSpecification(:helloworld)
@register app greet("Jinguo") == "Hello, Jinguo"

# test input types
@enum ENM X Y Z
const dict = Dict(3=>5)
@register app identity((X, 1.0, 1, "string", nothing, [1, 2], dict , ComplexF64)) == (X, 1.0, 1, "string", nothing, [1, 2], dict, ComplexF64)