import jugsaw.jugsaw as jug
import numpy as np
import pdb

context = jug.ClientContext()
app = jug.request_app(context, "GenericTN")
inputs = app.solve[0].input()
result = app.solve[0].result()
#res = app.greet("Jinguo")
res = app.solve[0]((
        (  # Jugsaw.Graph
            10,
            np.array([[1,2], [2,3], [3,4], [4,5], [5,6], [6,7], [7,8], [8,9], [9,10]]).T
        ),
        [1, 1, 1, 1, 1, 1, 1, 1, 1, 1],  # weights
        [], # open vertices
        {}  # fixed vertices
    ),
    (),    # SizeMax()
    usecuda = False,
    seed = 2
)
print(f"job id = {res.job_id}")
# TODO: if job errors, the following request hangs, should be fixed
print(res())
pdb.set_trace()
