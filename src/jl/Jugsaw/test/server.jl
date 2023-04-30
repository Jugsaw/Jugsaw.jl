using Test
using Jugsaw

@testset "parse fcall" begin
    app = AppSpecification(:testapp)
    @register app sin(0.5)::Float64
    path = joinpath(@__DIR__, "testapp")
    # saving demos
    Jugsaw.save_demos(path, app)
    @test isfile(joinpath(path, "demos.json"))
    @test isfile(joinpath(path, "types.json"))
    # loading demos
    newdemos, newtypes = Jugsaw.load_demos_from_dir(path, app)
    @test newdemos == app
    @test newtypes isa Jugsaw.JugsawIR.TypeTable

    # parse function call
    fcall, _ = Jugsaw.JugsawIR.json4(first(app.method_demos)[2].first)
    type_sig, req = Jugsaw.parse_fcall(fcall::String, app.method_demos)
    @test req == first(app.method_demos)[2].first
    @test Jugsaw.nfunctions(app) == 1
    empty!(app)
    @test Jugsaw.nfunctions(app) == 0
end