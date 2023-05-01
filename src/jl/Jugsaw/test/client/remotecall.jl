using Test, Jugsaw, JugsawIR, Jugsaw.Client

@testset "local call" begin
    path = joinpath(dirname(@__DIR__), "testapp")
    r = LocalHandler(path)
    app = request_app(r, :testapp)
    @test app isa Client.App
    @test Client.render_jsoncall("JugsawFunctionCall{sin, Tuple{Int}}", "sin", (2,), (;)) isa String
    @test_throws ErrorException @call r sin(2.0)
    open(f->write(f, "2"), joinpath(path, "result.json"), "w")
    @test 2 == (@call r app.sin(2.0;))()
end

@testset "server-client" begin
    # start service
    app = AppSpecification(:testapp)
    @register app sin(cos(0.5))::Float64
    t = Jugsaw.serve(app; is_async=true)

    # run tasks
    remote = RemoteHandler()  # on the default port
    @test healthz(remote).status == "OK"
    app = request_app(remote, :testapp)
    @test app isa Client.App

    #fetch
    @test (@test_demo remote app.sin)
    #request_app, healthz, dapr_config, delete

    # turn down service
    schedule(t, InterruptException(), error=true)
end