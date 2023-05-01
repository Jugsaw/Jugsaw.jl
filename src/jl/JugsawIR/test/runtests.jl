using Test
using JugsawIR

@testset "lark" begin
    include("lark.jl")
end

@testset "serialize" begin
    include("serialize.jl")
end

@testset "types" begin
    include("types.jl")
end