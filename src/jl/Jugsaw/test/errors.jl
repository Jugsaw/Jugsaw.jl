using Test, Jugsaw, JugsawIR, HTTP
using JugsawIR.JSON3

@testset "error" begin
    e = NoDemoException("sin", ["cos"])
    @test Jugsaw._error_msg(e) == "method does not exist, got: sin, available functions are:\n  - cos"
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
    fcall, _ = JugsawIR.julia2ir(first(app.method_demos)[2].fcall)
    
    r = AppRuntime(app)
    req = HTTP.Request("POST", "/actors/testapp.buggy/0/method/", ["Content-Type" => "application/json"], fcall; context=Dict(:params=>Dict("actor_id"=>"0")))
    ret = Jugsaw.act!(r, req)
    object_id = JSON3.read(String(ret.body)).object_id
    @test r.state_store[object_id] === nothing
    @test length(r.state_store.store) == 1

    # call functions not exist
    fcall2 = "{\"fields\":[{\"fields\":[],\"type\":\"Base.sinx\"},{\"fields\":[0.8775825618903728],\"type\":\"Core.Tuple{Core.Float64}\"},{\"fields\":[],\"type\":\"Core.NamedTuple{(), Core.Tuple{}}\"}],\"type\":\"JugsawIR.Call{Base.sinx, Core.Tuple{Core.Float64}, Core.NamedTuple{(), Core.Tuple{}}}\"}"
    req = HTTP.Request("POST", "/actors/testapp.sinx/0/method/", ["Content-Type" => "application/json"], fcall2; context=Dict(:params=>Dict("actor_id"=>"0")))
    res = Jugsaw.act!(r, req)
    @test res.status == 400
    @test length(r.state_store.store) == 1
    @show JSON3.read(res.body).error

    # trigger the bug
    fcall3 = """{"fields":[{"fields":[],"type":"Main.buggy"},{"fields":[-0.5],"type":"Core.Tuple{Core.Float64}"},{"fields":[],"type":"Core.NamedTuple{(), Core.Tuple{}}"}],"type":"JugsawIR.Call{Main.buggy, Core.Tuple{Core.Float64}, Core.NamedTuple{(), Core.Tuple{}}}"}"""
    req = HTTP.Request("POST", "/actors/testapp.buggy/0/method/", ["Content-Type" => "application/json"], fcall3; context=Dict(:params=>Dict("actor_id"=>"0")))
    res = Jugsaw.act!(r, req)
    @test res.status == 200
    @test length(r.state_store.store) == 2
    
    req = HTTP.Request("POST", "/actors/testapp.buggy/0/method/fetch", ["Content-Type" => "application/json"], String(res.body); context=Dict(:params=>Dict("actor_id"=>"0")))
    res = Jugsaw.fetch(r, req)
    @test res.status == 400
    @show JSON3.read(res.body).error
end