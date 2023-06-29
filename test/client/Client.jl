using Test
using Jugsaw.Client
using Jugsaw

@testset "Core" begin
    include("Core.jl")
end

@testset "parser" begin
    include("parser.jl")
end

@testset "remotecall" begin
    include("remotecall.jl")
end