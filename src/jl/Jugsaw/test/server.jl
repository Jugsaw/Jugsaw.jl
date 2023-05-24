using Test
using Jugsaw, JugsawIR
using HTTP, JugsawIR.JSON3, URIs
using Jugsaw.Server

@testset "mock event" begin
    dapr = MockEventService(joinpath(@__DIR__, ".daprtest"))
    mkpath(dapr.save_dir)
    @test get_timeout(dapr) == 1.0

    job_id = string(Jugsaw.uuid4())

    # status updated
    status = JobStatus(id=job_id, status=Jugsaw.Server.succeeded)
    publish_status(dapr, status)
    @test fetch_status(dapr, job_id; timeout=1.0) == (:ok, status)

    # another status updated
    status = JobStatus(id=job_id, status=Jugsaw.Server.failed)
    publish_status(dapr, status)
    @test fetch_status(dapr, job_id; timeout=1.0) == (:ok, status)

    # incorrect id triggers the timeout
    @test fetch_status(dapr, "asfd"; timeout=1.0) == (:timed_out, nothing)

    save_state(dapr, job_id, Dict("x"=>42))
    st, d = load_state(dapr, job_id, Dict("y"=>4); timeout=1.0)
    @test st == :ok
    @test d == Dict("x"=>42)
end

@testset "app runtime" begin
    app = AppSpecification(:testapp)
    @register app sin(cos(0.5))::Float64
    dapr = MockEventService(joinpath(@__DIR__, ".daprtest"))
    r = AppRuntime(app, dapr)
    @test r isa AppRuntime

    # simple call
    job_id = string(Jugsaw.uuid4())
    adt, = JugsawIR.julia2adt(JugsawIR.Call(sin, (0.5,), (;)))
    thisdemo = JugsawIR.JugsawDemo(JugsawIR.Call(sin, (0.6,), (;)), sin(0.6), Dict{String, String}())
    addjob!(r, job_id, round(Int, time()), "jugsaw", 1.0, adt, thisdemo)
    st, res = load_state(dapr, job_id, thisdemo.result; timeout=1.0)
    @test res ≈ sin(0.5)
    @test fetch_status(dapr, job_id; timeout=1.0)[2].status == Jugsaw.Server.succeeded

    # nested call
    job_id = string(Jugsaw.uuid4())
    adt, = JugsawIR.julia2adt(JugsawIR.Call(sin, (JugsawIR.Call(cos, (0.7,), (;)),), (;)))
    thisdemo = JugsawIR.JugsawDemo(JugsawIR.Call(sin, (0.6,), (;)), sin(0.6), Dict{String, String}())
    addjob!(r, job_id, round(Int, time()), "jugsaw", 1.0, adt, thisdemo)
    st, res = load_state(dapr, job_id, thisdemo.result; timeout=1.0)
    @test res ≈ sin(cos(0.7))
    @test fetch_status(dapr, job_id; timeout=1.0)[2].status == Jugsaw.Server.succeeded
end

@testset "app runtime error" begin
    # error call
    function buggy(x)
        if x < 0
            error("you did not catch me!")
        end
    end
    app = AppSpecification(:testapp)
    dapr = MockEventService(joinpath(@__DIR__, ".daprtest"))
    @register app sin(cos(0.5))::Float64
    @register app buggy(0.5)
    r = AppRuntime(app, dapr)

    job_id = string(Jugsaw.uuid4())
    adt1, = JugsawIR.julia2adt(JugsawIR.Call(buggy, (1.0,), (;)))
    adt2, = JugsawIR.julia2adt(JugsawIR.Call(buggy, (-1.0,), (;)))
    thisdemo = JugsawIR.JugsawDemo(JugsawIR.Call(buggy, (0.6,), (;)), buggy(0.6), Dict{String, String}())
    # normal call
    addjob!(r, job_id, round(Int, time()), "jugsaw", 1.0, adt1, thisdemo)
    st, res = load_state(dapr, job_id, thisdemo.result; timeout=1.0)
    @test fetch_status(dapr, job_id; timeout=1.0)[2].status == Jugsaw.Server.succeeded
    # trigger error
    addjob!(r, job_id, round(Int, time()), "jugsaw", 1.0, adt2, thisdemo)
    st, res = load_state(dapr, job_id, thisdemo.result; timeout=1.0)
    @test fetch_status(dapr, job_id; timeout=1.0)[2].status == Jugsaw.Server.failed
end

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
    fcall, _ = julia2ir(first(app.method_demos["sin"]).fcall)
    
    r = AppRuntime(app)
    req = HTTP.Request("POST", "/actors/testapp.sin/0/method/", ["Content-Type" => "application/json"], fcall)
    ret = Jugsaw.act!(r, req)
    @test JSON3.read(String(ret.body)).object_id isa String
    #@test req == first(app.method_demos)[2].fcall
    @test Jugsaw.nfunctions(app) == 2
    object_id = JSON3.read(String(ret.body)).object_id
    @test r.state_store[object_id] ≈ sin(0.8775825618903728)
    @test length(r.state_store.store) == 1

    # nested function call
    cos_call = """{"fields":["cos",
        {"fields":[8.0],"type":"Core.Tuple{Core.Float64}"},
        {"fields":[],"type":"Core.NamedTuple{(), Core.Tuple{}}"}],
        "type":"JugsawIR.Call"}"""

    fcall3 = """{"fields":["sin",
        {"fields":[$cos_call],"type":"Core.Tuple{Core.Float64}"},
        {"fields":[],"type":"Core.NamedTuple{(), Core.Tuple{}}"}],
        "type":"JugsawIR.Call"}"""
    req = HTTP.Request("POST", "/actors/testapp.sinx/0/method/", ["Content-Type" => "application/json"], fcall3)
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
    demo = first(first(app.method_demos)[2])
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
    demo = first(first(app.method_demos)[2])
    @test feval(demo.fcall) == A()
    demo = app.method_demos[app.method_names[1]][1]
    @test fevalself(demo.fcall) == (1, 2, 3)
end

@testset "routes" begin
    app = AppSpecification(:testapp)
    @register app sin(cos(0.5))::Float64
    ar = AppRuntime(app)
    r = Jugsaw.get_router(ar)
    # services
    @test JSON3.read(r(HTTP.Request("GET", "/healthz"))).status == "OK"
    @test JSON3.read(r(HTTP.Request("GET", "/dapr/config"))).entities == []
    demo = app.method_demos["sin"][1]
    req, types = julia2ir(Call(demo.fcall.fname, (8.0,), (;)))
    id = JSON3.read(r(HTTP.Request("POST", "/actors/testapp.sin/method/", ["Content-Type" => "application/json"], req)).body).object_id
    @test id isa String
    fet = JSON3.write((; object_id=id))
    @test ir2julia(r(HTTP.Request("POST", "/actors/testapp.sin/method/fetch", ["Content-Type" => "application/json"], fet)), demo.result) ≈ sin(8.0)
    uri = URI("http://jugsaw.co")
    loaded_app = Jugsaw.Client.load_app(r(HTTP.Request("GET", "/apps/testapp/demos")), uri)
    @test loaded_app isa Jugsaw.Client.App
    @test_broken r(HTTP.Request("DELETE", "/actors/testapp.sin/0"))
end