using Test
using Jugsaw

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
    fcall, _ = Jugsaw.JugsawIR.json4(first(app.method_demos)[2].fcall)
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
    ret, rett = state_store[key]
    res = JugsawIR.parse4(ret, demo.result)
    @test res == feval(demo.fcall, 0.6)

    # empty!
    empty!(app)
    @test Jugsaw.nfunctions(app) == 0
end