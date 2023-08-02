using Test, Jugsaw.Client
using JugsawIR
using Markdown

@testset "parse" begin
    app = Jugsaw.APP; empty!(app)
    @register testapp begin
        sin(cos(0.5))::Float64
        cos(0.5)
    end
    path = joinpath(@__DIR__, "testapp")
    # saving demos
    Jugsaw.save_demos(path, app)
    @test isfile(joinpath(path, "demos.json"))
 
    context = Client.ClientContext()
    app = Client.load_app(context, read(joinpath(@__DIR__, "testapp", "demos.json"), String))
    println(app)
    @test app.cos isa Client.DemoRef
    print(app.cos.demo.meta["docstring"])
    @test app.cos.demo.meta["docstring"] isa String
end
