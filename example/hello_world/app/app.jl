using Jugsaw

"""
    greet(x)

A function returns "Hello, \$x".
"""
greet(x::String) = "Hello2, $x"

function generate_app()
    app = AppSpecification(:helloworld)
    @register app greet("Jinguo") == "Hello2, Jinguo"
    return app
end
# Jugsaw.Server.serve(r; localmode=false, host="127.0.0.1")
