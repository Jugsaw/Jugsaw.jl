using Test, Jugsaw, JugsawIR, Jugsaw.Client, Jugsaw.Server
using JugsawIR.JSON3

@testset "server-client" begin
    # start service
    sapp = AppSpecification(:testapp)
    r = AppRuntime(sapp, InMemoryEventService())
    @register sapp sin(cos(0.5))::Float64
    context = Client.ClientContext()
    t = Jugsaw.Server.serve(r; is_async=true)

    try
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
    catch e
        Base.rethrow(e)
    finally
        # turn down service
        schedule(t, InterruptException(), error=true)
    end
end

@testset "request in server mode" begin
    # start the service
    sapp = AppSpecification(:testapp)
    @register sapp sin(cos(0.5))::Float64
    r = AppRuntime(sapp, InMemoryEventService())
    # request in remote mode
    context = Client.ClientContext(; localmode=false)
    t = Jugsaw.Server.serve(r; is_async=true, localmode=false)

    try
        @test Client.new_request(context, Val(:healthz)).status == 200
        @test Client.new_request(context, Val(:demos)).status == 200
        job_id = string(Jugsaw.uuid4())
        fcall = Jugsaw.Call(:sin, (1.0,), (;))
        @test Client.new_request(context, Val(:job), job_id, fcall).status == 200
        @test Client.new_request(context, Val(:fetch), job_id).status == 200
        @test Client.new_request(context, Val(:api), fcall, "JuliaLang").status == 200
    catch e
        Base.rethrow(e)
    finally
        # turn down service
        schedule(t, InterruptException(), error=true)
    end
end