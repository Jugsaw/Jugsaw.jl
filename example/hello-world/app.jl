using Jugsaw

"""
    greet(xxx)

A function returns "Hello, xxxx".
"""
greet(x::String) = "Hello, $x"
buggy(x, y) = x < y ? x : error("errored!")

# test input types
const dict = Dict(3 => 5)

@register helloworld begin
    greet("Jinguo") == "Hello, Jinguo"
    identity((1.0, 1, "string", nothing, [1, 2], dict)) == (1.0, 1, "string", nothing, [1, 2], dict)
    buggy(1, 2)
end