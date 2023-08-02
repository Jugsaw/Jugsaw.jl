import Jugsaw, Revise

Revise.includet("app.jl")
@info "Running application: " Jugsaw.APP

# reload the application on change
Jugsaw.Server.serve(Jugsaw.APP; watched_files=["app.jl"])

