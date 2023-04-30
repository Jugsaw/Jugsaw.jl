using Jugsaw, Test

@testset "template" begin
    include("template.jl")
end

@testset "typeuniverse" begin
    include("typeuniverse.jl")
end

@testset "server" begin
    include("server.jl")
end