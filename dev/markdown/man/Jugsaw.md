


<a id='Jugsaw'></a>

<a id='Jugsaw-1'></a>

# Jugsaw


<a id='APIs'></a>

<a id='APIs-1'></a>

## APIs

<a id='Jugsaw.load_config_file!-Tuple{String}' href='#Jugsaw.load_config_file!-Tuple{String}'>#</a>
**`Jugsaw.load_config_file!`** &mdash; *Method*.



```julia
load_config_file!(configfile::String) -> Dict{String, Any}

```

Load configurations from the input `.toml` file.


<a target='_blank' href='https://github.com/Jugsaw/Jugsaw.jl/blob/67fe35adcb19f0ef135dac9c8cd8ecae936fd21d/src/config.jl#L12' class='documenter-source'>source</a><br>

<a id='Jugsaw.@register' href='#Jugsaw.@register'>#</a>
**`Jugsaw.@register`** &mdash; *Macro*.



```julia
@register appname expression
```

Register functions to the Jugsaw application, where `appname` is the name of applications. A function can be registered as a demo, which can take the following forms.

```julia
@register appname f(args...; kwargs...) == result    # a function call + a test
@register appname f(args...; kwargs...) ≈ result     # similar to the above
@register appname f(args...; kwargs...)::T           # a function call with assertion of the return type
@register appname f(args...; kwargs...)              # a function call
@register appname begin ... end                      # a sequence of function
```

The [`@register`](Jugsaw.md#Jugsaw.@register) macro checks and executes the expression. If the tests and type asserts in the expression does not hold, an error will be thrown. Otherwise, both the top level function call and those appear in the input arguments will be registered.

Registered functions are stored in `Jugsaw.APP`.


<a target='_blank' href='https://github.com/Jugsaw/Jugsaw.jl/blob/67fe35adcb19f0ef135dac9c8cd8ecae936fd21d/src/register.jl#L81-L99' class='documenter-source'>source</a><br>

<a id='Jugsaw.AppSpecification' href='#Jugsaw.AppSpecification'>#</a>
**`Jugsaw.AppSpecification`** &mdash; *Type*.



```julia
mutable struct AppSpecification
```

The application specification.

**Fields**

  * `name::Symbol`
  * `method_names::Vector{String}`
  * `method_demos::Dict{String, JugsawDemo}`


<a target='_blank' href='https://github.com/Jugsaw/Jugsaw.jl/blob/67fe35adcb19f0ef135dac9c8cd8ecae936fd21d/src/register.jl#L1' class='documenter-source'>source</a><br>

<a id='Jugsaw.NoDemoException' href='#Jugsaw.NoDemoException'>#</a>
**`Jugsaw.NoDemoException`** &mdash; *Type*.



```julia
struct NoDemoException <: Exception
```

This error was thrown when a demo matching the target type signature is not found.

**Fields**

  * `func_sig::Any`
  * `methods::Any`


<a target='_blank' href='https://github.com/Jugsaw/Jugsaw.jl/blob/67fe35adcb19f0ef135dac9c8cd8ecae936fd21d/src/errors.jl#L1' class='documenter-source'>source</a><br>

