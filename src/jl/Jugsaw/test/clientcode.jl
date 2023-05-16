using Test, Jugsaw

@testset "generate code" begin
    code = generate_code(Jugsaw.JuliaLang(), :isapprox, (1.0, 2,0), (; atol=1e-8))
    @show code
end