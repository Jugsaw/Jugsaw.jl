using Test, Jugsaw.Client, Jugsaw

@testset "App" begin
    # start service
    sapp = AppSpecification(:testapp)
    @register sapp sin(cos(0.5))::Float64
    t = Jugsaw.serve(sapp; is_async=true)
    try
        # run tasks
        remote = RemoteHandler()  # on the default port
        #delete
        app = request_app(remote, :testapp)
        println(app)
        @test app isa Client.App
        @test app[:uri] == remote.uri
        @test length(@doc app.sin) > 3
        as = app.sin
        println(as)
        @test as isa DemoRefs
        as1 = as[1]
        @test as1 isa DemoRef
        println(as1)
        @test test_demo(as1)
        @test test_demo(app)
        #@test (@doc as)
        #@test length(@doc as) > 3
    catch e
        rethrow(e)
    finally
        schedule(t, InterruptException(), error=true)
    end
end