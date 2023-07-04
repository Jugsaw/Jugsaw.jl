import Jugsaw, Revise

Revise.includet("app.jl")
Jugsaw.Server.serve(Jugsaw.APP; watched_files=["app.jl"])