# Design

## Overview

<!--
- What Jugsaw is
- What we provide
    - For application developers
        - Bridge the gap between users and developers?
    - For general users
        - A world of ready-to-use applications?
-->

## The Problem We Want to Solve

### A Common Case

Alice is user new to quantum computing. She is familiar with the Python
programming language. And she wants to try some algorithms implemented in Julia.

Bob is a quantum computing package developer. The package is written in Julia
and he wants to have more users to try it out without learning the
implementation details.

TODO:

- @GiggleLiu enrich this story
- Insert an image here for better understanding.

### 

### The Scope of the Problem We Want to Solve

- Domains/Subjects
- Programming Languages

## Existing Solutions

TODO: list the pros and cons of each existing solution.

- PyCall.jl/PythonCall.jl
- HuggingFace
- Stipple.jl

## Proposed Solution

### Key Concepts

#### Contributor

Contributors are those who are familiar with a specific library. They can develop applications with the help of [Jugsaw SDK](@ref) and deploy them on our app store.

#### User

Different from [**Contributor**](@ref), general users do not need to understand all the underlying implementation details.

For entry level users, they are more interested in interacting with the [**Application**](@ref)s through the web portal. 

For experienced users, they can take an [Application](@ref) as a black box and reliably embed it in their own code logic. For some complex algorithms, they may even compose an arbitrary computation graph and schedule it on our cluster.

#### Application

An application is usually a collection of [Jug](@ref)s or [Saw](@ref)s. [Developer](@ref)s can specify the required resource to run the application. Our system may automatically create several instances based on the number of queueing requests.

#### Job

#### Jug(stateful computation unit)

#### Saw(stateless computation unit)

#### Data Model

#### Future

### Core Components

TODO: Add images to explain how they are assembled in our product.

#### Jugsaw SDK

For now we'll focus on the Julia SDK. But the ideas should also apply to SDK in
other languages in the future.

Basically, the SDK contains two parts: the **client** side and the **server** side.

##### Jugsaw Server

- [`Jug`](@ref)/[`Saw`](@ref) manager
    - (De)Activate Jug/Saw
    - Dispatch requests
    - State Monitoring

!!! note
    The manager is **STATIC** at the moment. This means that, once started, the manager can only handle requests to predefined [Jug](@ref)s or [Saw](@ref)s.

**Example:**

```julia
# app.jl

## Jug
greet(name::String="World")::String = "Hello, $name!"

## Saw
Base.@kwdef struct Counter
    name::String = greet()
    n::Ref{Int} = Ref(0)
end

(c::Counter)(x::Int=1)::String = c.n[] += x
```

```julia
# manager.jl
using Jugsaw

register(Jug, greet)
register(Saw, Counter)

serve()
```

```yaml
# config.yaml
- name: hello-world
- version: v0.1.0
- authors:
  - Alice
  - Bob
```

##### Jugsaw Client

- Submit job
- Fetch data from [`Future`](@ref)
- (De)Serializer

```julia
using Jugsaw

open(Client(endpoint="https://api.jugsaw.co"), app="hello-world") do app
    # Saw
    msg = app.greet()
    println(msg[])

    # Jug
    counter = app.Counter()
    counter()
    counter(2)
    println(counter(3)[])

    # JugSaw
    x = app.Counter(name=app.greet())
    x()
    x(2)
    println(string(x)[])
end
```

#### Jugsaw Runtime

- Scheduling
- Auto-scaling

#### Jugsaw Proto

#### Jugsaw Frontend

- Communication strategy
- Embedding in other tools
    - Jupyter Notebook
    - Pluto
    - Documenter.jl

### Key Features

#### Pluggable

### The Ecosystem Around Jugsaw

## Comparison with Other Products

- [HuggingFace Spaces](https://huggingface.co/spaces)
- [Ray](https://docs.ray.io/)
- [Pluto](https://github.com/fonsp/Pluto.jl)

## FAQ

### Why do You Choose to Work on This Field?

- Our aspiration
- The potential market size

### Why **You**?

### Why Julia?


## References

- [Ray AIR Technical Whitepaper](https://docs.google.com/document/d/1bYL-638GN6EeJ45dPuLiPImA8msojEDDKiBx3YzB4_s/preview#heading=h.ru1taexewu7i)