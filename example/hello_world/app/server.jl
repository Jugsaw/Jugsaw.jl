import Jugsaw

using Revise
includet("app.jl")

dapr = Jugsaw.Server.InMemoryEventService()
server_task = Ref(Jugsaw.Server.start_server(generate_app(), dapr; localmode=false))

entr(["app.jl"], [], postpone=true) do
    Jugsaw.Server.stop_server(server_task[])
    server_task[] = Jugsaw.Server.start_server(generate_app(), dapr; localmode=false)
end