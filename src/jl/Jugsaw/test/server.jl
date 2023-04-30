using Test
using Jugsaw

@testset "parse fcall" begin
    app = AppSpecification(:testapp)
    @register app sin(0.5)::Float64
    path = joinpath(@__DIR__, "testapp")
    # saving demos
    Jugsaw.save_demos(path, app.method_demos)
    @test isfile(joinpath(path, "demos.json"))
    @test isfile(joinpath(path, "types.json"))
    # loading demos
    newdemos, newtypes = Jugsaw.load_demos_from_dir(path, app.method_demos)
    @test newdemos == app.method_demos
    @test newtypes isa Jugsaw.JugsawIR.TypeTable

    # parse function call
    fcall, _ = Jugsaw.JugsawIR.json4(first(app.method_demos)[2].first)
    @test Jugsaw.parse_fcall(fcall::String, app.method_demos) == first(app.method_demos)[2].first
end