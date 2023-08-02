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
@register Testapp begin
    # register by demo
    greet("Jugsaw")
end

