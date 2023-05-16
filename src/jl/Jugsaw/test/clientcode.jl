using Test, Jugsaw
using JugsawIR

@testset "generate code" begin
    code = generate_code(Jugsaw.JuliaLang(), "jugsaw.co", :testapp, JugsawIR.Call(:isapprox, (1.0, 2.0), (; atol=1e-8)))
    @test code == """using Jugsaw.Client
app = request_app(RemoteHandler("jugsaw.co"), :testapp)
app.isapprox(1.0, 2.0; atol = 1.0e-8)"""
end