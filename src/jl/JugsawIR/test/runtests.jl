using Test
using JugsawIR

@testset "lark" begin
    include("lark.jl")
end

@testset "serialize" begin
    include("serialize.jl")
end