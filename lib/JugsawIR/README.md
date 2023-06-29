# JugsawIR

[![Stable](https://img.shields.io/badge/docs-stable-blue.svg)](https://GiggleLiu.github.io/JugsawIR.jl/stable/)
[![Dev](https://img.shields.io/badge/docs-dev-blue.svg)](https://GiggleLiu.github.io/JugsawIR.jl/dev/)
[![Build Status](https://github.com/GiggleLiu/JugsawIR.jl/actions/workflows/CI.yml/badge.svg?branch=main)](https://github.com/GiggleLiu/JugsawIR.jl/actions/workflows/CI.yml?query=branch%3Amain)
[![Coverage](https://codecov.io/gh/GiggleLiu/JugsawIR.jl/branch/main/graph/badge.svg)](https://codecov.io/gh/GiggleLiu/JugsawIR.jl)

```julia
julia> using JugsawIR: julia2ir, ir2julia

julia> ir2julia(julia2ir(Polynomial([2,3,5.0])); mod=Main)
Dict{String, Any} with 3 entries:
  "Array{Float64, 1}"       => Vector{Float64}
  "__main__"                => Polynomial(2.0 + 3.0*x + 5.0*x^2)
  "Polynomial{Float64, :x}" => Polynomial{Float64, :x}

julia> println(julia2ir(Polynomial([2,3,5.0])))
{"Array{Float64, 1}":{"__type__":"DataType","name":"Array{Float64, 1}","fieldtypes":[]},
"Polynomial{Float64, :x}":{"__type__":"DataType","name":"Polynomial{Float64, :x}","fieldtypes":["Array{Float64, 1}"]},
"__main__":{"__type__":"Polynomial{Float64, :x}","coeffs":{"__type__":"Array{Float64, 1}","size":[3],"storage":"AAAAAAAAAEAAAAAAAAAIQAAAAAAAABRA"}}
}
```