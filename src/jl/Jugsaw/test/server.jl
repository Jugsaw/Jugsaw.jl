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
    @test isfile(joinpath(path, "types.json"))
    # loading demos
    newdemos, newtypes = Jugsaw.load_demos_from_dir(path, app)
    @test newdemos == app
    @test newtypes isa Jugsaw.JugsawIR.TypeTable

    # parse function call
    fcall, _ = json4(first(app.method_demos)[2].fcall)
    type_sig, req = Jugsaw.parse_fcall(fcall::String, app.method_demos)
    @test req == first(app.method_demos)[2].fcall
    @test Jugsaw.nfunctions(app) == 2
    # act!
    # 1. create a state store
    key = string(Jugsaw.uuid4())
    state_store = Jugsaw.StateStore(Dict{String, Jugsaw.Future}())
    state_store[key] = Jugsaw.Future()

    # 2. create a demo message call
    demo = first(app.method_demos)[2]
    fcall = JugsawFunctionCall(demo.fcall.fname, (0.6,), (;))
    msg = Jugsaw.Message(fcall, Jugsaw.ObjectRef(key))

    # 3. compute and fetch the result
    Jugsaw.act!(state_store, demo.fcall, msg)
    ret = state_store[key]
    res = JugsawIR.parse4(ret, demo.result)
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
    demo = app.method_demos["JugsawIR.JugsawFunctionCall{Base.sin, Core.Tuple{Core.Float64}, Core.NamedTuple{(), Core.Tuple{}}}"]
    req, types = json4(JugsawFunctionCall(demo.fcall.fname, (8.0,), (;)))
    id = JSON3.read(r(HTTP.Request("POST", "/actors/testapp.sin/0/method/", ["Content-Type" => "application/json"], req)).body).object_id
    @test id isa String
    fet = JSON3.write((; object_id=id))
    @test parse4(r(HTTP.Request("POST", "/actors/testapp.sin/0/method/fetch", ["Content-Type" => "application/json"], fet)), demo.result) ≈ sin(8.0)
    loaded_app = Jugsaw.Client.load_app(r(HTTP.Request("GET", "/apps/testapp/demos")))
    @test loaded_app isa Jugsaw.Client.App
    @test_broken r(HTTP.Request("DELETE", "/actors/testapp.sin/0"))
end