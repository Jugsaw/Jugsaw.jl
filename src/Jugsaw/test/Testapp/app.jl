# Please check Jugsaw documentation: TBD
using Jugsaw

"
    greet(x)

This is the docstring, in which **markdown** grammar and math equations are supported

```math
x^2
```
"
greet(x::String) = "Hello, $(x)!"

# create an application
app = Jugsaw.AppSpecification(:Testapp)

@register app begin
    # register by demo
    greet("Jugsaw")
    # register by test case, here four functions `sin`, `cos`, `^`, `+` are registered.
    sin(0.5) ^ 2 + cos(0.5) ^ 2 ≈ 1.0
end

