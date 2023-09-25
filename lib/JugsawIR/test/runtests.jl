using Test
using JugsawIR

@testset "typeext" begin
    include("typeext.jl")
end

@testset "Core" begin
    include("Core.jl")
end

@testset "pressure test" begin
    include("brutaltest.jl")
end

@testset "type spec" begin
    include("typespec.jl")
end