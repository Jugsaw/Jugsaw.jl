
<a id='Develop-and-deploy-a-Jugsaw-app'></a>

<a id='Develop-and-deploy-a-Jugsaw-app-1'></a>

# Develop and deploy a Jugsaw app


<a id='My-First-Jugsaw-Application'></a>

<a id='My-First-Jugsaw-Application-1'></a>

## My First Jugsaw Application


<a id='Step-1.-Create-a-Jugsaw-app'></a>

<a id='Step-1.-Create-a-Jugsaw-app-1'></a>

### Step 1. Create a Jugsaw app


To create a Jugsaw app in your working folder, please open a [julia REPL](https://docs.julialang.org/en/v1/stdlib/REPL/) and type


```julia
julia> using Jugsaw

julia> Jugsaw.Template.init(:Test)
[ Info: Generated Jugsaw app `Test` at folder: /home/leo/jcode/Jugsaw/Test
┌ Info: Success, please type `julia --project server.jl` to debug your application locally.
└ To upload your application to Jugsaw website, please check https://jugsaw.github.io/Jugsaw/dev/developer

julia> readdir("Test")
5-element Vector{String}:
 "Dockerfile"     # The script for specifying how to build the docker image
 "Project.toml"   # Julia package dependency file
 "README"         # A description of the Jugsaw app
 "app.jl"         # Jugsaw application file, which contains functions to be registered
 "server.jl"      # A script for serving the Jugsaw application a web service
```


<a id='Step-2.-Launch-the-debug-page'></a>

<a id='Step-2.-Launch-the-debug-page-1'></a>

### Step 2. Launch the debug page


To develop the application, please enter the application folder and type


```bash
cd Test
julia --project=. -e "using Pkg; Pkg.instantiate()"
julia --project server.jl
```


The debug page will be opened in your default browser, and you can start to edit the application file `app.jl` in your favorite editor. Edits to the application file `app.jl` will be reflected immediately to the debug page, which is powered by [Revise.jl](https://github.com/timholy/Revise.jl).


<a id='Step-3.-Play-with-the-application'></a>

<a id='Step-3.-Play-with-the-application-1'></a>

### Step 3. Play with the application


**Method 1: Launch from the debug page** By clicking the `submit` button, you can launch a request to the demo function. The returned value is a `uuid` string, which is the id of the job. With this id, you can fetch the result of the job by clicking the `fetch` button. The returned value is a JSON payload, which contains the result of the job.


**Method 2: Launch from the clients** We provide a **Julia** client and a **python** client. With the Julia client, you can launch a request to the demo function by typing


```julia
julia> using Jugsaw.Client

julia> context = Client.ClientContext(endpoint="http://0.0.0.0:8088")

julia> app = Client.request_app(context, :testapp)

julia> lazyret = app.greet("Jugsaw")

julia> lazyret()
"Hello, Jugsaw!"
```


For more details, please check the [Julia client guide](client-julia.md) and [python client guide](client-python.md).


**Method 3: Launch with JSON Payload**


If you check the debug page, you will find that the application is already registered with a demo function `greet`. By clicking the `json` button, you can see the JSON payload of the demo function. You can launch a request to the demo function with curl


```bash
(base) ➜  ~ curl -X POST http://0.0.0.0:8088/v1/proj/unspecified/app/helloworld/ver/lastest/func/greet -H 'Content-Type: application/json' -H 'ce-id: 22022cf3-f656-46b2-ac70-24b4a260af48' -H 'ce-source: any' -H 'ce-specversion: 1.0' -H 'ce-type: any' -d '{
    "id": "c7dd5ad6-eed5-47ca-a901-e8662b6a00e4",
    "created_at": 1695575206349,
    "created_by": "unspecified",
    "maxtime": 60,
    "fcall": {      
        "fname": "greet",
        "args": [   
            "Jugsaw"
        ],
        "kwargs": {}
    }
}'
```


By replacing the `"fcall"` field with the json payload of the demo function, you can launch a request to the demo function.


<a id='Jugsaw-application-file'></a>

<a id='Jugsaw-application-file-1'></a>

## Jugsaw application file


The `app.jl` in the template is printed as the following.


````julia
using Jugsaw

"""
    greet(x)

This is the docstring, in which **markdown** grammar and math equations are supported

```math
x^2
```
"""
greet(x::String) = "Hello, $(x)!"

# create an application
@register testapp begin
    # register by demo
    greet("Jugsaw")
end
````


`Jugsaw` is already included as your project dependency in `Project.toml`, you can add more dependencies to your project file [in the standard Julian way](https://pkgdocs.julialang.org/v1/environments/). A Jugsaw app is specified as a [`Jugsaw.AppSpecification`](man/Jugsaw.md#Jugsaw.AppSpecification) instance, in which you can register functions. A function or an API can be registered as a *demo* with the [`@register`](man/Jugsaw.md#Jugsaw.@register) macro, where a *demo* is a using case of a function with concrete input values. It can be either a function call or a test case. In the above example, the functions registered in application `:Test` are `greet`, `sin`, `cos`, `^` and `+`.


<a id='Deploy-a-Jugsaw-app-to-Hugging-Face'></a>

<a id='Deploy-a-Jugsaw-app-to-Hugging-Face-1'></a>

## Deploy a Jugsaw app to Hugging Face


To deploy a Jugsaw app to [Huggingface](https://huggingface.co/), please follow the steps below.


1. Create a Hugging Face [Space](https://huggingface.co/spaces).
2. Push the Jugsaw app to the git repository of the Space.
3. Hopefully, the app will be deployed automatically. If you encounter any error, please add an issue to [Jugsaw repository](https://github.com/Jugsaw/Jugsaw.jl).

