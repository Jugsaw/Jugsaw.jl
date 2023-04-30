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
end