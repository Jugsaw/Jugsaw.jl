import jugsaw.jugsaw as jug
import pdb

context = jug.ClientContext()
app = jug.request_app(context, "GenericTN")
res = app.greet("Jinguo")
print(f"job id = {res.job_id}")
# TODO: if job errors, the following request hangs
print(res())
pdb.set_trace()
