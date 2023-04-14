using Test
using Jugsaw.Template: init

@testset "init" begin
    init(basedir=joinpath(@__DIR__), appname=:Testapp)
end