using Test, Jugsaw, JugsawIR, Jugsaw.Client
using JugsawIR.JSON3

@testset "local call" begin
    path = joinpath(dirname(@__DIR__), "testapp")
    r = LocalHandler(path)
    app = request_app(r, :testapp)
    @test app isa Client.App
    open(f->write(f, "2"), joinpath(path, "result.json"), "w")
    @test 2 == app.sin(2.0)
end

@testset "server-client" begin
    # start service
    sapp = AppSpecification(:testapp)
    @register sapp sin(cos(0.5))::Float64
    t = Jugsaw.serve(sapp; is_async=true)

    # run tasks
    remote = RemoteHandler()  # on the default port
    @test healthz(remote).status == "OK"
    @test dapr_config(remote) == []

    app = request_app(remote, :testapp)
    @test app isa Client.App

    #fetch
    @test test_demo(app.sin)
    @test dapr_config(remote) == ["sin"]

    # call
    obj = call(app.sin[1], 3.0)
    @test obj isa Client.LazyReturn
    @test obj() ≈ sin(3.0)

    #delete
    @test delete(remote, app, :sin)

    # turn down service
    schedule(t, InterruptException(), error=true)
end