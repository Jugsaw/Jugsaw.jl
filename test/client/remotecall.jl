using Test, Jugsaw, JugsawIR, Jugsaw.Client, Jugsaw.Server
using JugsawIR.JSON3

@testset "get kwargs" begin
    @test Client.get_kws_from_type(JugsawIR.type2str((;) |> typeof)) == String[]
    @test Client.get_kws_from_type(JugsawIR.type2str((; x=3, y=5) |> typeof)) == ["x", "y"]
end

@testset "server-client" begin
    # start service
    sapp = Jugsaw.APP; empty!(sapp)
    r = AppRuntime(sapp, InMemoryEventService())
    @register testapp sin(cos(0.5))::Float64
    context = Client.ClientContext()
    t = Jugsaw.Server.simpleserve(r; is_async=true)

    try
        # healthz
        @test healthz(context).status == "OK"

        # run tasks
        app = request_app(context, :testapp)
        @test app isa Client.App

        #fetch
        @test test_demo(app.sin)

        # call
        f = app.sin
        obj = call(f.context, f.demo, 3.0)
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
    sapp = Jugsaw.APP; empty!(sapp)
    @register testapp sin(cos(0.5))::Float64
    r = AppRuntime(sapp, InMemoryEventService())
    # request in remote mode
    context = Client.ClientContext(; localurl=false, endpoint="http://localhost:8082")
    t = Jugsaw.Server.simpleserve(r; is_async=true, localurl=false, port=8082)

    try
        @test Client.new_request(context, Val(:healthz)).status == 200
        @test Client.new_request(context, Val(:demos)).status == 200
        job_id = string(Jugsaw.uuid4())
        fcall = JugsawIR.julia2adt(Jugsaw.Call(:sin, (1.0,), (;)))[1]
        @test Client.new_request(context, Val(:job), job_id, fcall).status == 200
        @test Client.new_request(context, Val(:fetch), job_id).status == 200
        @test Client.new_request(context, Val(:api), fcall, "Julia").status == 200
    catch e
        Base.rethrow(e)
    finally
        # turn down service
        schedule(t, InterruptException(), error=true)
    end
end