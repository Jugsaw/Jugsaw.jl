using Test
using Jugsaw.Client
using Jugsaw

@testset "parser" begin
    include("parser.jl")
end

@testset "remotecall" begin
    include("remotecall.jl")
end