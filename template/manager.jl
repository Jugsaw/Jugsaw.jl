using Jugsaw

include("app.jl")

# setup the function greet
Jugsaw.register(greet)
function Jugsaw.time_space_complexity(variables::Vector{Float64}, ::typeof(greet), args...)
    return variables[1]  # constant, we can use enzyme to train these variables.
end

Jugsaw.serve()
