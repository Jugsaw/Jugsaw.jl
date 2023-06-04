import Jugsaw
import Revise
includet("app.jl")

# dapr = Jugsaw.Server.InMemoryEventService()
# server_task = Ref(Jugsaw.Server.start_server(app, dapr; localmode=false))

# entr(["app.jl"], [], postpone=true) do
#     Jugsaw.Server.stop_server(server_task[])
#     server_task[] = Jugsaw.Server.start_server(app, dapr; localmode=false)
# end

# function liveserve(app; watched_files, host::String="0.0.0.0", port::Int=8088, localmode::Bool=true)
#     dapr = Jugsaw.Server.InMemoryEventService()
#     server_task = Ref(Jugsaw.Server.start_server(app, dapr; localmode, host, port))

#     Revise.entr(watched_files, [], postpone=true) do
#         Jugsaw.Server.stop_server(server_task[])
#         server_task[] = Jugsaw.Server.start_server(app, dapr; localmode, host, port)
#     end
# end
Jugsaw.Server.liveserve(app; watched_files=[joinpath(@__DIR__,"app.jl")], localmode=false)