using Test
using Jugsaw.Template: init

@testset "init" begin
    init(basedir=@__DIR__, appname=:Testapp)
    @test length(readdir(joinpath(@__DIR__, "Testapp"))) == 4
end