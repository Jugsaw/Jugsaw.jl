using Test
using Jugsaw.Template: init

@testset "init" begin
    # broken since Jugsaw is not registered yet.
    @test_broken begin
        init(:Testapp, basedir=@__DIR__)
        length(readdir(joinpath(@__DIR__, "Testapp"))) == 4
    end
end