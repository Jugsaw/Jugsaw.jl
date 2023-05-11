using Test, Jugsaw

@testset "module and symbol" begin
    #m, s = Jugsaw.module_and_symbol(Jugsaw.protect_type(Dict))
    m, s = Jugsaw.module_and_symbol(Dict)
    @test m === Base
    @test s == :Dict
end