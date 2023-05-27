using Test, Jugsaw, JugsawIR, Jugsaw.Client
using JugsawIR.JSON3

@testset "server-client" begin
    # start service
    sapp = AppSpecification(:testapp)
    r = AppRuntime(sapp, InMemoryEventService())
    @register sapp sin(cos(0.5))::Float64
    t = Jugsaw.Server.serve(r; is_async=true)

    context = Client.ClientContext()

    # healthz
    @test healthz(context).status == "OK"

    # run tasks
    app = request_app(context, :testapp)
    @test app isa Client.App

    #fetch
    @test test_demo(app.sin)

    # call
    obj = call(app.sin[1], 3.0)
    @test obj isa Client.LazyReturn
    @test obj() ≈ sin(3.0)

    # turn down service
    schedule(t, InterruptException(), error=true)
end

@testset "request in server mode" begin
    # start the service
    sapp = AppSpecification(:testapp)
    @register sapp sin(cos(0.5))::Float64
    r = AppRuntime(sapp, InMemoryEventService())
    t = Jugsaw.Server.serve(r; is_async=true, localmode=false)

    # request in remote mode
    context = Client.ClientContext(; localmode=false)

    # turn down service
    schedule(t, InterruptException(), error=true)
end