using Jugsaw

greet(x::String="Jugsaw") = "Hello, $(x)!"

register(greet)

serve()