using Jugsaw, Test

@testset "config loading" begin
    @test Jugsaw.GLOBAL_CONFIG["port"] == 8088
    Jugsaw.load_config_file!(joinpath(@__DIR__, "config-test.toml"))
    @test Jugsaw.GLOBAL_CONFIG["port"] == 8089
end