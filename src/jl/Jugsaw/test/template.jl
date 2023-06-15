using Test
using Jugsaw.Template: init

@testset "init" begin
    init(:Testapp, basedir=@__DIR__)
    @test length(readdir(joinpath(@__DIR__, "Testapp"))) == 4
end