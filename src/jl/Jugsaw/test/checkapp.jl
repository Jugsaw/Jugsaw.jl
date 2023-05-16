using Test, Jugsaw

@testset "helloworld" begin
    dir = joinpath(dirname(dirname(dirname(dirname(@__DIR__)))), "example", "hello_world", "app")
    println(dir)
    @test Jugsaw.checkapp(dir)
end