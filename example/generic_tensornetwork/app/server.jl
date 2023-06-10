import Jugsaw, Revise

Revise.includet("app.jl")
Jugsaw.Server.serve(app; watched_files=["app.jl"])