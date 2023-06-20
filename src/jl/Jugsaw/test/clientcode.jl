using Test, Jugsaw
using JugsawIR

@testset "Julia code" begin
    @enum TEnum EA EB
    democall = JugsawIR.Call(sum, (1.0, [1, 2, 3], Dict(2=>3), EA, 1+2im), (; a=1e-8, b=Dict(2=>4)))
    adt, typetable = JugsawIR.julia2adt(democall)
    code = generate_code("Julia", "jugsaw.co", :testapp, adt, typetable)
    @test code == """using Jugsaw.Client
app = request_app(ClientContext(; endpoint = "jugsaw.co"), :testapp)
app.sum(1.0, [1, 2, 3], Dict(2=>3), "EA", (1, 2); a=1.0e-8, b=Dict(2=>4))"""
end