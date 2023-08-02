


<a id='Jugsaw'></a>

<a id='Jugsaw-1'></a>

# Jugsaw


<a id='APIs'></a>

<a id='APIs-1'></a>

## APIs

<a id='Jugsaw.generate_code-Tuple{String, Any, Any, Any, JugsawExpr, JugsawExpr}' href='#Jugsaw.generate_code-Tuple{String, Any, Any, Any, JugsawExpr, JugsawExpr}'>#</a>
**`Jugsaw.generate_code`** &mdash; *Method*.



```julia
generate_code(
    lang::String,
    endpoint,
    appname,
    fname,
    fcall::JugsawExpr,
    typetable::JugsawExpr
) -> String

```

Generate code for target language.

**Arguments**

  * `lang` can be a string or an [`AbstractLang`](@ref) instance that specifies the target language.

Please use `subtypes(AbstractLang)` for supported client languages.

  * `endpoint` is the url for service provider, e.g. it can be [https://www.jugsaw.co](https://www.jugsaw.co).
  * `appname` is the application name.
  * `fcall` is a [`JugsawExpr`](JugsawIR.md#JugsawIR.JugsawExpr) that specifies the function call.
  * `typetable` is a [`TypeTable`](JugsawIR.md#JugsawIR.TypeTable) instance with the type definitions.


<a target='_blank' href='https://github.com/Jugsaw/Jugsaw.jl/blob/d8a5d63e86ed98d83c8df50ecc4abc5ba52fcbe3/src/clientcode.jl#L6' class='documenter-source'>source</a><br>

<a id='Jugsaw.@register-Tuple{Symbol, Any}' href='#Jugsaw.@register-Tuple{Symbol, Any}'>#</a>
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

The [`@register`](Jugsaw.md#Jugsaw.@register-Tuple{Symbol, Any}) macro checks and executes the expression. If the tests and type asserts in the expression does not hold, an error will be thrown. Otherwise, both the top level function call and those appear in the input arguments will be registered.

Registered functions are stored in `Jugsaw.APP`.


<a target='_blank' href='https://github.com/Jugsaw/Jugsaw.jl/blob/d8a5d63e86ed98d83c8df50ecc4abc5ba52fcbe3/src/register.jl#L89-L107' class='documenter-source'>source</a><br>

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


<a target='_blank' href='https://github.com/Jugsaw/Jugsaw.jl/blob/d8a5d63e86ed98d83c8df50ecc4abc5ba52fcbe3/src/register.jl#L1' class='documenter-source'>source</a><br>

<a id='Jugsaw.NoDemoException' href='#Jugsaw.NoDemoException'>#</a>
**`Jugsaw.NoDemoException`** &mdash; *Type*.



```julia
struct NoDemoException <: Exception
```

This error was thrown when a demo matching the target type signature is not found.

**Fields**

  * `func_sig::Any`
  * `methods::Any`


<a target='_blank' href='https://github.com/Jugsaw/Jugsaw.jl/blob/d8a5d63e86ed98d83c8df50ecc4abc5ba52fcbe3/src/errors.jl#L1' class='documenter-source'>source</a><br>

