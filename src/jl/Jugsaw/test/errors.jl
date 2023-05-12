using Test, Jugsaw, JugsawIR, HTTP
using JugsawIR.JSON3

@testset "error" begin
    e = NoDemoException("sin", ["cos"])
    @test Jugsaw._error_msg(e) == "method does not exist, got: sin, available functions are: [\"cos\"]"
    @test Jugsaw._error_response(e).status == 400
end

@testset "error handling" begin
    app = AppSpecification(:testapp)
    function buggy(x)
        if x < 0
            error("you did not catch me!")
        end
    end
    @register app buggy(0.5)

    # parse function call
    fcall, _ = JugsawIR.julia2ir(first(app.method_demos).second[1].fcall)
    
    r = AppRuntime(app)
    req = HTTP.Request("POST", "/actors/testapp.buggy/0/method/", ["Content-Type" => "application/json"], fcall)
    ret = Jugsaw.act!(r, req)
    object_id = JSON3.read(String(ret.body)).object_id
    @test r.state_store[object_id] === nothing
    @test length(r.state_store.store) == 1

    # call functions not exist
    fcall2 = """{"fields":["sinx",{"fields":[0.5],"type":"Core.Tuple{Core.Float64}"},{"fields":[],"type":"Core.NamedTuple{(), Core.Tuple{}}"}],"type":"JugsawIR.Call"}"""
    req = HTTP.Request("POST", "/actors/testapp.sinx/0/method/", ["Content-Type" => "application/json"], fcall2)
    res = Jugsaw.act!(r, req)
    @test res.status == 400
    @test length(r.state_store.store) == 1
    @show JSON3.read(res.body).error

    # trigger the bug
    fcall3 = """{"fields":["buggy",{"fields":[-0.5],"type":"Core.Tuple{Core.Float64}"},{"fields":[],"type":"Core.NamedTuple{(), Core.Tuple{}}"}],"type":"JugsawIR.Call"}"""
    req = HTTP.Request("POST", "/actors/testapp.buggy/0/method/", ["Content-Type" => "application/json"], fcall3)
    res = Jugsaw.act!(r, req)
    @test res.status == 200
    @test length(r.state_store.store) == 2
    
    req = HTTP.Request("POST", "/actors/testapp.buggy/0/method/fetch", ["Content-Type" => "application/json"], String(res.body))
    res = Jugsaw.fetch(r, req)
    @test res.status == 400
    @show JSON3.read(res.body).error
end