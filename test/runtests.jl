using Jugsaw, Test

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

@testset "clientcode" begin
    include("clientcode.jl")
end

@testset "template" begin
    include("template.jl")
end

# @testset "checkapp" begin
#     include("checkapp.jl")
# end