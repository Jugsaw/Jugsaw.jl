using Test, Jugsaw, JugsawIR, HTTP
using JugsawIR.JSON3
using Jugsaw.Server

@testset "error" begin
    e = NoDemoException("sin", ["cos"])
    @test Jugsaw._error_msg(e) == "method does not exist, got: sin, available functions are: [\"cos\"]"
    @test Jugsaw._error_response(e).status == 400
end

@testset "error handling" begin
    app = AppSpecification(:testapp)
    function buggy(x)
        if x < 0
            error("you did not catch me!")
        end
    end
    @register app buggy(0.5)
    r = AppRuntime(app, InMemoryEventService())

    # parse function call
    fcall = first(app.method_demos).second[1].fcall
    
    resp1, resp2, obj, job_id = Jugsaw.launch_and_fetch(r, fcall)
    @test resp2.status == 200
    @test length(r.dapr.object_store) == 1

    @test fetch_status(r.dapr, job_id; timeout=1.0)[2].status == Jugsaw.Server.succeeded

    # call functions not exist
    fcall2 = JugsawIR.Call(:sinx, (0.5,), (;))
    resp1, resp2, obj, job_id = Jugsaw.launch_and_fetch(r, fcall2)
    @test resp1.status == 400
    @test resp2.status == 400
    @test length(r.dapr.object_store) == 1

    @test fetch_status(r.dapr, job_id; timeout=1.0)[2].status == Jugsaw.Server.failed

    # trigger the bug
    fcall3 = JugsawIR.Call(:buggy, (-0.5,), (;))
    resp1, resp2, obj, job_id = Jugsaw.launch_and_fetch(r, fcall3)
    @test resp1.status == 200
    @test resp2.status == 400
    @test length(r.dapr.object_store) == 1

    # query status
    @test fetch_status(r.dapr, job_id; timeout=1.0)[2].status == Jugsaw.Server.failed
end