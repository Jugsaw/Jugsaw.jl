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

#### Developer
#### User
#### Application
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

##### Jugsaw Client

- Submit job
- Fetch data from [`Future`](@ref)
- (De)Serializer

##### Jugsaw Server

- [`Jug`](@ref)/[`Saw`](@ref) manager, register

#### Jugsaw Runtime

- Scheduling
- Auto-scaling

#### Jugsaw Proto

#### Jugsaw Frontend

- Communication strategy

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