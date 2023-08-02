import Jugsaw, Revise

Revise.includet("app.jl")
@info "Running application: " Jugsaw.APP
Jugsaw.Server.serve(Jugsaw.APP; watched_files=["app.jl"])
