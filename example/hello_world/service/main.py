from jugsaw import App

import gradio as gr

app = App("helloworld")

def greet(name):
    res = app.greet["0"](name, sig="Jugsaw.JugsawFunctionCall{Main.#greet, Core.Tuple{Core.String}, Core.NamedTuple{(), Core.Tuple{}}}", fname="#greet")
    return res()

demo = gr.Interface(fn=greet, inputs="text", outputs="text")
    
if __name__ == "__main__":
    demo.launch()   