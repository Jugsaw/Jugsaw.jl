using Test
using Jugsaw, JugsawIR
using HTTP, JugsawIR.JSON3

@testset "parse fcall" begin
    app = AppSpecification(:testapp)
    @register app sin(cos(0.5))::Float64
    path = joinpath(@__DIR__, "testapp")
    # saving demos
    Jugsaw.save_demos(path, app)
    @test isfile(joinpath(path, "demos.json"))
    # loading demos
    newdemos, newtypes = Jugsaw.load_demos_from_dir(path, app)
    @test newdemos == app
    @test newtypes isa Jugsaw.JugsawIR.TypeTable

    # parse function call
    fcall, _ = julia2ir(first(app.method_demos).second[1].fcall)
    
    r = AppRuntime(app)
    req = HTTP.Request("POST", "/actors/testapp.sin/0/method/", ["Content-Type" => "application/json"], fcall; context=Dict(:params=>Dict("actor_id"=>"0")))
    ret = Jugsaw.act!(r, req)
    @test JSON3.read(String(ret.body)).object_id isa String
    #@test req == first(app.method_demos)[2].fcall
    @test Jugsaw.nfunctions(app) == 2
    object_id = JSON3.read(String(ret.body)).object_id
    @test r.state_store[object_id] ≈ sin(0.8775825618903728)
    @test length(r.state_store.store) == 1

    # nested function call
    cos_call = """{"fields":[{"fields":[],"type":"Base.cos"},
    {"fields":[8.0],"type":"Core.Tuple{Core.Float64}"},
    {"fields":[],"type":"Core.NamedTuple{(), Core.Tuple{}}"}],
    "type":"JugsawIR.Call{Base.cos, Core.Tuple{Core.Float64}, Core.NamedTuple{(), Core.Tuple{}}}"}"""

    fcall3 = """{"fields":[{"fields":[],"type":"Base.sin"},
    {"fields":[$cos_call],"type":"Core.Tuple{Core.Float64}"},
    {"fields":[],"type":"Core.NamedTuple{(), Core.Tuple{}}"}],
    "type":"JugsawIR.Call{Base.sin, Core.Tuple{Core.Float64}, Core.NamedTuple{(), Core.Tuple{}}}"}"""
    req = HTTP.Request("POST", "/actors/testapp.sinx/0/method/", ["Content-Type" => "application/json"], fcall3; context=Dict(:params=>Dict("actor_id"=>"0")))
    ret = Jugsaw.act!(r, req)
    @test ret.status == 200
    object_id = JSON3.read(String(ret.body)).object_id
    @test length(r.state_store.store) == 3
    @test r.state_store[object_id] ≈ sin(cos(8.0))
    # act!
    # 1. create a state store
    key = string(Jugsaw.uuid4())
    state_store = Jugsaw.StateStore(Dict{String, Jugsaw.Future}())
    state_store[key] = Jugsaw.Future()

    # 2. create a demo message call
    demo = first(app.method_demos)[2]
    fcall = Call(demo.fcall.fname, (0.6,), (;))
    msg = Jugsaw.Message(fcall, Jugsaw.ObjectRef(key))

    # 3. compute and fetch the result
    Jugsaw.do!(state_store, demo.fcall, msg)
    res = state_store[key]
    @test res == feval(demo.fcall, 0.6)

    # empty!
    empty!(app)
    @test Jugsaw.nfunctions(app) == 0

    # register a type function
    @register app Tuple([1, 2, 3]) == (1, 2, 3)
    struct A end
    @register app A()
    @test Jugsaw.nfunctions(app) == 2
    demo = first(app.method_demos)[2]
    @test feval(demo.fcall) == A()
    demo = app.method_demos[app.method_sigs[1]]
    @test fevalself(demo.fcall) == (1, 2, 3)
end

@testset "routes" begin
    app = AppSpecification(:testapp)
    @register app sin(cos(0.5))::Float64
    ar = AppRuntime(app)
    r = Jugsaw.get_router(ar)
    # services
    # HTTP.register!(r, "GET", "/healthz", _ -> JSON3.write((; status="OK")))
    # HTTP.register!(r, "GET", "/dapr/config", _ -> JSON3.write((; entities=collect(keys(runtime.actors)))))
    # HTTP.register!(r, "POST", "/actors/{actor_type_name}/{actor_id}/method/", req -> act!(runtime, req))
    # HTTP.register!(r, "POST", "/actors/{actor_type_name}/{actor_id}/method/fetch", req -> fetch(runtime, req))
    # HTTP.register!(r, "DELETE", "/actors/{actor_type_name}/{actor_id}", req -> deactivate!(runtime, req))
    @test JSON3.read(r(HTTP.Request("GET", "/healthz"))).status == "OK"
    @test JSON3.read(r(HTTP.Request("GET", "/dapr/config"))).entities == []
    demo = app.method_demos["sin"][1]
    req, types = julia2ir(Call(demo.fcall.fname, (8.0,), (;)))
    id = JSON3.read(r(HTTP.Request("POST", "/actors/testapp.sin/0/method/", ["Content-Type" => "application/json"], req)).body).object_id
    @test id isa String
    fet = JSON3.write((; object_id=id))
    @test ir2julia(r(HTTP.Request("POST", "/actors/testapp.sin/0/method/fetch", ["Content-Type" => "application/json"], fet)), demo.result) ≈ sin(8.0)
    loaded_app = Jugsaw.Client.load_app(r(HTTP.Request("GET", "/apps/testapp/demos")))
    @test loaded_app isa Jugsaw.Client.App
    @test_broken r(HTTP.Request("DELETE", "/actors/testapp.sin/0"))
end