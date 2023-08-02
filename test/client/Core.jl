using Test, Jugsaw.Client, Jugsaw, Jugsaw.Server

@testset "App" begin
    # start service
    sapp = Jugsaw.APP; empty!(sapp)
    @register testapp begin
        sin(cos(0.5))::Float64
        cos(0.5)
    end
    dapr = InMemoryEventService()
    r = AppRuntime(sapp, dapr)
    t = Server.simpleserve(r; is_async=true)
    context = Client.ClientContext()
    try
        #delete
        app = request_app(context, :testapp)
        println(app)
        @test app isa Client.App
        @test app[:context].appname == :testapp
        @test length(@doc app.sin) > 3
        as = app.sin
        println(as)
        @test as isa DemoRef
        @test test_demo(as)
        @test test_demo(app)
        #@test (@doc as)
        #@test length(@doc as) > 3
    catch e
        #rethrow(e)
        println(e)
    finally
        schedule(t, InterruptException(), error=true)
    end
end