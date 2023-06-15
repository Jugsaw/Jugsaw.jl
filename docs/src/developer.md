# Develop and deploy a Jugsaw app

## Develop
Step 1. To create a Jugsaw app in your working folder, please open a [julia REPL](https://docs.julialang.org/en/v1/stdlib/REPL/) and type
```julia
julia> using Jugsaw

julia> Jugsaw.Template.init(:Test)
[ Info: Generated Jugsaw app `Test` at folder: /home/leo/jcode/Jugsaw/Test
┌ Info: Success, please type `julia --project server.jl` to debug your application locally.
└ To upload your application to Jugsaw website, please check https://jugsaw.github.io/Jugsaw/dev/developer

julia> readdir("Test")
5-element Vector{String}:
 "Dockerfile"     # The script for specifying how docker images are built
 "Project.toml"   # Julia package environment specification
 "README"         # A description of the Jugsaw app
 "app.jl"         # Jugsaw app, which contains functions and tests
 "server.jl"      # A script for serving the app
```
 
The [`Dockerfile`](https://docs.docker.com/develop/develop-images/dockerfile_best-practices/) (TODO: explain our Dockerfile) is for building the docker image, so that your application can be containerized and launched by a Jugsaw endpoint. Without special requirements, you have no need to change the contents in `Dockerfile`.

Step 2. To develop the application, please switch to the application folder, and type
```bash
julia --project server.jl
```
It will *live serve* the application locally at `0.0.0.0:8088`.
Any edit to the application file `app.jl` will be reflected immediately to the service, which is powered by [Revise](https://github.com/timholy/Revise.jl).
The `app.jl` in the template is printed as the following.

~~~julia
using Jugsaw

"
    greet(x)

This is the docstring, in which **markdown** grammar and math equations are supported

```math
x^2
```
"
greet(x::String) = "Hello, $(x)!"

# create an application
app = Jugsaw.AppSpecification(:Test)

@register app begin
    # register by demo
    greet("Jugsaw")
    # register by test case, here four functions `sin`, `cos`, `^`, `+` are registered.
    sin(0.5) ^ 2 + cos(0.5) ^ 2 ≈ 1.0
end
~~~

`Jugsaw` is already included as your project dependency in `Project.toml`, you can add more dependencies to your project file [in the standard Julian way](https://pkgdocs.julialang.org/v1/environments/).
A Jugsaw app is specified as a [`Jugsaw.AppSpecification`](@ref) instance, in which you can register functions.
A function or an API can be registered as a *demo* with the [`@register`](@ref) macro, where a *demo* is a using case of a function with concrete input values.
It can be either a function call or a test case.
In the above example, the functions registered in application `:Test` are `greet`, `sin`, `cos`, `^` and `+`.

## Deploy on the Jugsaw cloud (TODO)
To deploy a Jugsaw app, you must have a Jugsaw account. You can get a free account from [https://www.jugsaw.co](https://www.jugsaw.co). To setup a new Jugsaw app, you should go through the following steps
Once you app is ready, please check [deploy guide](https://jugsaw.github.io/Jugsaw/dev/developer) for a detailed guide.

First, you should add your Jugsaw deploy key to your repository secrets.
A Jugsaw deploy key can be obtained from the Jugsaw website -> Profile -> Deploy Key.

To set up repository secrets for GitHub action, follow the steps below:

1. Go to the GitHub repository where you want to set up the secrets.
2. Click on the "Settings" tab.
3. Click on the "Secrets" option.
4. Click on the "New repository secret" button.
5. Enter the name of the secret in the "Name" field as "JUGSAW_DEPLOY_KEY".
6. Enter the value of the secret in the "Value" field.
7. Click on the "Add secret" button.

In your GitHub action workflow file, reference the secrets using the syntax ${{ secrets.SECRET_NAME }}.

Note: It's important to keep your secrets secure and not include them in your code or make them publicly available.

## Deploy on a local machine (TODO)
!!! note
    This section is about deploying a containerized Jugsaw application on a local machine.
    If you are only interested in local deployment without docker, please use `julia --project server.jl` that detailed in the section [Develop](@ref).

1. [Install docker](https://docs.docker.com/engine/install/) on your local machine,
2. Pull the docker image from the remote,
3. Pull up the service by typing
```bash
...
```