using Test, Jugsaw
using JugsawIR

@testset "Julia code" begin
    democall = JugsawIR.Call(:f, (nothing, true, 1, 1.0, [1, 2, 3], [1 2; 3 4], Dict(2=>3), 1+2im), (; a=1e-8, b=Dict(2=>4)))
    adt, typetable = JugsawIR.julia2adt(democall)
    code = generate_code("Julia", "jugsaw.co", :testapp, :f, adt, typetable)
    @test code == """using Jugsaw.Client
app = request_app(ClientContext(; endpoint="jugsaw.co"), :testapp)
lazyreturn = app.f(nothing, true, 1, 1.0, [1, 2, 3], reshape([1, 3, 2, 4], 2, 2), Dict(2 => 3), (1, 2); a = 1.0e-8, b = Dict(2 => 4))
result = lazyreturn()  # fetch result"""
end

@testset "Python code" begin
    democall = JugsawIR.Call(:f, (nothing, true, 1, 1.0, [1, 2, 3], [1 2; 3 4], Dict(2=>3), 1+2im), (; a=1e-8, b=Dict(2=>4)))
    adt, typetable = JugsawIR.julia2adt(democall)
    code = generate_code("Python", "jugsaw.co", :testapp, :f, adt, typetable)
    @test code == """import jugsaw, numpy
app = jugsaw.request_app(jugsaw.ClientContext(endpoint="jugsaw.co"), "testapp")
lazyreturn = app.f(None, True, 1, 1.0, [1, 2, 3], numpy.reshape([1, 3, 2, 4], (2, 2), order='F'), {2:3}, (1, 2), a = 1.0e-8, b = {2:4})
result = lazyreturn()   # fetch result"""
end

@testset "Javascript code" begin
    democall = JugsawIR.Call(:f, (nothing, true, 1, 1.0, [1, 2, 3], [1 2; 3 4], Dict(2=>3), 1+2im), (; a=1e-8, b=Dict(2=>4)))
    adt, typetable = JugsawIR.julia2adt(democall)
    code = generate_code("Javascript", "jugsaw.co", :testapp, :f, adt, typetable)
    @test code == """<!-- include the jugsaw library -->
<script type="text/javascript" src="https://cdn.jsdelivr.net/gh/Jugsaw/Jugsaw/src/js/jugsawirparser.js"></script>

<!-- The function call -->
<script>
// call
const context = new ClientContext({endpoint:"jugsaw.co"})
const app_promise = request_app(context, "testapp")
// keyword arguments are: ["a", "b"]
app_promise.then(app=>app.call("f", [null, true, 1, 1.0, [[3], [1, 2, 3]], [[2, 2], [1, 3, 2, 4]], [[[2, 3]]], [1, 2]], [1.0e-8, [[[2, 4]]]])).then(console.log)
</script>"""
end