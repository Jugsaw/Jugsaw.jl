import Jugsaw, Revise

Revise.includet("app.jl")

# reload the application on change
Jugsaw.Server.serve(app; watched_files=["app.jl"])

