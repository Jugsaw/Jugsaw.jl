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
    app = Client.load_demos_from_dir(joinpath(dirname(@__DIR__), "testapp"))
    println(app)
    @test app.cos[] isa Client.Demo
    print(app.cos[].meta["docstring"])
    @test app.cos[].meta["docstring"] isa String
    #Client.print_app(app)
end