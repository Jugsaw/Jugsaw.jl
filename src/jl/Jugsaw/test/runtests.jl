using Jugsaw, Test

@testset "template" begin
    include("template.jl")
end

@testset "register" begin
    include("register.jl")
end

@testset "typeuniverse" begin
    include("typeuniverse.jl")
end

@testset "server" begin
    include("server.jl")
end

@testset "client" begin
    include("client/Client.jl")
end

@testset "errors" begin
    include("errors.jl")
end

@testset "checkapp" begin
    include("checkapp.jl")
end