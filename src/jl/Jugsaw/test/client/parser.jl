using Test, Jugsaw.Client
using JugsawIR
using Markdown

@testset "decode_fname" begin
    purename(x) = Client.purename(Meta.parse(x))
    @test purename("Base.cos") == :cos
    @test purename("Test.Base.cos") == :cos
    @test purename("x.cos{x, y}") == :cos
    @test purename("cos{}") == :cos
end

@testset "parse" begin
    context = Client.ClientContext()
    app = Client.load_app(context, read(joinpath(dirname(@__DIR__), "server", "testapp", "demos.json"), String))
    println(app)
    @test app.cos[1] isa Client.DemoRef
    print(app.cos[1].demo.meta["docstring"])
    @test app.cos[1].demo.meta["docstring"] isa String
end
