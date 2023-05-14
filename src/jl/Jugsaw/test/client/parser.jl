using Test, Jugsaw.Client
using JugsawIR
using Markdown

@testset "parse" begin
    app = Client.load_demos_from_dir(joinpath(dirname(@__DIR__), "testapp"))
    println(app)
    @test app.cos[1] isa Client.DemoRef
    print(app.cos[1].demo.meta["docstring"])
    @test app.cos[1].demo.meta["docstring"] isa String
end