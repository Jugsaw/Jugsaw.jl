using Jugsaw

"""
    greet(x)

A function returns "Hello, \$x".
"""
greet(x::String) = "Hello, $x"

app = AppSpecification(:helloworld)
@register app greet("Jinguo") == "Hello, Jinguo"

r = Jugsaw.Server.AppRuntime(app, Jugsaw.Server.InMemoryEventService())
Jugsaw.Server.serve(r; localmode=false, host="127.0.0.1")
