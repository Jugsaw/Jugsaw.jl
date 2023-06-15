


<a id='Jugsaw'></a>

<a id='Jugsaw-1'></a>

# Jugsaw


<a id='APIs'></a>

<a id='APIs-1'></a>

## APIs

<a id='Jugsaw.generate_code-Tuple{String, Vararg{Any}}' href='#Jugsaw.generate_code-Tuple{String, Vararg{Any}}'>#</a>
**`Jugsaw.generate_code`** &mdash; *Method*.



```julia
generate_code(lang, endpoint::String, appname::Symbol, fcall::JugsawADT, democall::JugsawIR.Call)
```

Generate code for target language.

**Arguments**

  * `lang` can be a string or an [`AbstractLang`](@ref) instance that specifies the target language.

Please use `subtypes(AbstractLang)` for supported client languages.

  * `endpoint` is the url for service provider, e.g. it can be [https://www.jugsaw.co](https://www.jugsaw.co).
  * `appname` is the application name.
  * `fcall` is a [`JugsawADT`](JugsawIR.md#JugsawIR.JugsawADT) that specifies the function call.
  * `democall` is the demo instance of that function call.


<a target='_blank' href='https://github.com/Jugsaw/Jugsaw.jl/blob/6015de0a47fd0e1fa3315929fbf489183839d5ea/src/jl/Jugsaw/src/clientcode.jl#L6-L18' class='documenter-source'>source</a><br>

<a id='Jugsaw.@register-Tuple{Any, Any}' href='#Jugsaw.@register-Tuple{Any, Any}'>#</a>
**`Jugsaw.@register`** &mdash; *Macro*.



```julia
@register app expression
```

Register a function to the application. A function can be registered as a demo, which can take the following forms.

```julia
@register app f(args...; kwargs...) == result    # a function call + a test
@register app f(args...; kwargs...) ≈ result     # similar to the above
@register app f(args...; kwargs...)::T           # a function call with assertion of the return type
@register app f(args...; kwargs...)              # a function call
@register app begin ... end                      # a sequence of function
```

The [`@register`](Jugsaw.md#Jugsaw.@register-Tuple{Any, Any}) macro checks and executes the expression. If the tests and type asserts in the expression does not hold, an error will be thrown. Otherwise, both the top level function call and those appear in the input arguments will be registered.


<a target='_blank' href='https://github.com/Jugsaw/Jugsaw.jl/blob/6015de0a47fd0e1fa3315929fbf489183839d5ea/src/jl/Jugsaw/src/register.jl#L109-L125' class='documenter-source'>source</a><br>

<a id='Jugsaw.AppSpecification' href='#Jugsaw.AppSpecification'>#</a>
**`Jugsaw.AppSpecification`** &mdash; *Type*.



```julia
struct AppSpecification
```

The application specification.

**Fields**

  * `name::Symbol`
  * `method_names::Vector{String}`
  * `method_demos::Dict{String, Vector{JugsawDemo}}`


<a target='_blank' href='https://github.com/Jugsaw/Jugsaw.jl/blob/6015de0a47fd0e1fa3315929fbf489183839d5ea/src/jl/Jugsaw/src/register.jl#L1' class='documenter-source'>source</a><br>

<a id='Jugsaw.NoDemoException' href='#Jugsaw.NoDemoException'>#</a>
**`Jugsaw.NoDemoException`** &mdash; *Type*.



```julia
struct NoDemoException <: Exception
```

This error was thrown when a demo matching the target type signature is not found.

**Fields**

  * `func_sig::Any`
  * `methods::Any`


<a target='_blank' href='https://github.com/Jugsaw/Jugsaw.jl/blob/6015de0a47fd0e1fa3315929fbf489183839d5ea/src/jl/Jugsaw/src/errors.jl#L1' class='documenter-source'>source</a><br>

