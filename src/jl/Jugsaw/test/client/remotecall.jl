using Test, Jugsaw, JugsawIR, Jugsaw.Client
using JugsawIR.JSON3

@testset "local call" begin
    path = joinpath(dirname(@__DIR__), "testapp")
    r = LocalHandler(path)
    app = request_app(r, :testapp)
    @test app isa Client.App
    @test Client.render_jsoncall("Call{sin, Tuple{Int}}", "sin", (2,), (;)) isa String
    @test_throws ErrorException @call r sin(2.0)
    open(f->write(f, "2"), joinpath(path, "result.json"), "w")
    @test 2 == (@call r app.sin(2.0;))()
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
    #delete
    app = request_app(remote, :testapp)
    @test app isa Client.App

    #fetch
    @test (@test_demo remote app.sin)
    @test dapr_config(remote) == [JSON3.read("{\"JugsawIR.Call{Base.sin, Core.Tuple{Core.Float64}, Core.NamedTuple{(), Core.Tuple{}}}\": \"0\"}")]

    @test_broken delete(remote, app, :sin, "0")
    @test_broken dapr_config(remote) == []

    # call
    obj = @call remote app.sin(3.0; )
    @test obj isa Client.LazyReturn
    @test obj() ≈ sin(3.0)

    # turn down service
    schedule(t, InterruptException(), error=true)
end