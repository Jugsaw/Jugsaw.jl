using Jugsaw
using Hello: greet

register(() -> greet, "greet")

serve()