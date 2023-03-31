## App
greet(name::String="World")::String = "Hello, $(name)!"


## It is highly recommended to include some tests in your app.
using Test

@testset "jugsaw app" begin
    @test greet("World") == "Hello, World!"
end