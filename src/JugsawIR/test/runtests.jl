using Test
using JugsawIR

@testset "lark" begin
    include("lark.jl")
end

@testset "adt" begin
    include("adt.jl")
end

@testset "ir" begin
    include("ir.jl")
end

@testset "Core" begin
    include("Core.jl")
end

@testset "pressure test" begin
    include("brutaltest.jl")
end