using Jugsaw, Test

@testset "config" begin
    include("config.jl")
end

@testset "register" begin
    include("register.jl")
end

@testset "server" begin
    include("server/server.jl")
end

@testset "client" begin
    include("client/Client.jl")
end

@testset "errors" begin
    include("errors.jl")
end

@testset "template" begin
    include("template.jl")
end