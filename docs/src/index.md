```@meta
CurrentModule = Jugsaw
```

# Jugsaw

[Jugsaw](https://www.jugsaw.co) is a toolkit designed to assist scientific computing scientists in deploying their applications to the cloud. Applications are deployed on the Jugsaw website as Jugsaw apps, which consist of a set of functions.


!!! note
    Currently, these functions must be written in Julia or encapsulated within a [Julia](https://www.julialang.org) wrapper ([C, Fortran](https://docs.julialang.org/en/v1/manual/calling-c-and-fortran-code/), [Python](https://github.com/cjdoris/PythonCall.jl)).

# Get started

The *developer* guide and *end user* guides can be found bellow.

The *developer* guide is about how to create and register a Jugsaw app. A Jugsaw app must be written in [Julia](https://julialang.org/) or contained in a Julia wrapper.
* Get started as Jugsaw app [developer](developer.md).


The *end user* guides are about how to access the Jugsaw app through the application web page or multi-language clients. The list of supported client languages include
* Get started as [Julia](client-julia.md) end user.
* Get started as [Python](client-python.md) end user.

## Manual

```@contents
Pages = [
    "developer.md",
    "client-julia.md",
    "client-python.md",
    "man/Jugsaw.md",
    "man/JugsawIR.md"
]
Depth = 1
```
