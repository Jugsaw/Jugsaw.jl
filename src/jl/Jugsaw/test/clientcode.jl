using Test, Jugsaw
using JugsawIR

@testset "generate code" begin
    democall = JugsawIR.Call(:isapprox, (1.0, 2.0), (; atol=1e-8))
    adt, = JugsawIR.julia2adt(democall)
    code = generate_code(Jugsaw.JuliaLang(), "jugsaw.co", :testapp, adt, democall)
    @test Jugsaw.fexpr(Jugsaw.JuliaLang(), adt, democall) == :(isapprox(1.0, 2.0; atol = 1.0e-8))
    @test code == """using Jugsaw.Client
app = request_app(ClientContext(; endpoint = "jugsaw.co"), :testapp)
app.isapprox(1.0, 2.0; atol = 1.0e-8)"""

    adt, = JugsawIR.julia2adt(JugsawIR.Call(:+, (1.0+2im, 2.0-1im), (;)))
    democall = JugsawIR.Call(:add, (1.0+2im, 2.0-1im), (;))
    code = Jugsaw.fexpr(Jugsaw.JuliaLang(), adt, democall)
    @test code == :(+((1.0, 2.0), (2.0, -1.0); ))
end