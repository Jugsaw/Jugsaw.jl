# Julia Client

## Install
`Jugsaw.Client` is a submodule of the Julia package [Jugsaw](https://github.com/Jugsaw/Jugsaw).
To install Jugsaw, please [open Julia's interactive session (known as REPL)](https://docs.julialang.org/en/v1/manual/getting-started/) and type the following command

```julia
julia> using Pkg; Pkg.add("Jugsaw")
```

## Get started by example

To complete your first Jugsaw function call, please copy-paste the following code into a julia REPL.

```julia
using Jugsaw.Client
context = ClientContext(endpoint="https://api.jugsaw.co")
app = request_app(context, :helloworld)
lazyreturn = app.greet[1]("Jinguo"; )
result = lazyreturn()  # fetch result
```

This example will be explained line by line in the following.

1. The first line imports the julia client module.

2. The second line defines the client context.
```julia
context = ClientContext(endpoint="https://api.jugsaw.co")
```
In a client context, you can specify the endpoint that providing computing services.
Here, we choose the official Jugsaw endpoint. For debugging a local Jugsaw application, the default endpoint is "http://0.0.0.0:8088".

3. The third line fetches the application.
```julia
app = jugsaw.request_app(context, "helloworld")
```
Here, we use the "helloworld" application as an example.
A Jugsaw app contains a list of functions and their using cases.
One can type `app.<TAB>` in a julia REPL to get a list of available functions.
More applications could be found in the [Jugsaw website](https://apps.jugsaw.co).

4. The fourth line launches a function call request to the remote.
```julia
lazyreturn = app.greet("Jugsaw")
```
Since a function may support multiple *input patterns*, we use `app.greet[1]` to select the first registered implementation of the `greet` function.
The indexing can be ommited in this case because the `greet` function here has only one implementation, i.e. `lazyreturn = app.greet("Jugsaw")` is also correct here.
To get help on this function, just type `?app.greet` in a julia REPL.
Alternatively, help message and *input patterns* could be found on the [application detail page](https://apps.jugsaw.co/helloworld/details) on the Jugsaw website.
The return value is a `LazyReturn` object that containing the job id information.

5. The last line fetches the results.
```julia
result = lazyreturn()   # fetch result
```

## Advanced features
* Elastic computing resources (not yet ready).
* Function piplining (not yet ready).
* Local deployment (not yet ready).