import jugsaw.jugsaw as jug

context = jug.ClientContext()
app = jug.request_app(context, "GenericTN")
app.greet("Jinguo")
