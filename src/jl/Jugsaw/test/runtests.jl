using Jugsaw, Test

@testset "template" begin
    include("template.jl")
end

@testset "typeuniverse" begin
    include("typeuniverse.jl")
end