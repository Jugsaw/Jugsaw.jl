using Test, Jugsaw, JugsawIR, HTTP
using JugsawIR.JSON3
using Jugsaw.Server

@testset "error" begin
    e = NoDemoException("sin", ["cos"])
    @test Jugsaw._error_msg(e) == "method does not exist, got: sin, available functions are: [\"cos\"]"
    @test Jugsaw.Server._error_response(e).status == 400
end

@testset "error handling" begin
    app = Jugsaw.APP; empty!(app)
    function buggy(x)
        if x < 0
            error("you did not catch me!")
        end
    end
    @register testapp buggy(0.5)
    r = AppRuntime(app, InMemoryEventService())
    context = Client.ClientContext()

    # parse function call
    fcall = JugsawIR.julia2adt(first(app.method_demos).second[1].fcall)[1]
    
    job_id = string(Jugsaw.uuid4())
    req = Client.new_request_obj(context, Val(:job), job_id, fcall)
    resp1 = Server.job_handler(r, req)
    @test resp1.status == 200

    req = Client.new_request_obj(context, Val(:fetch), job_id)
    resp2 = Server.fetch_handler(r, req)
    @test resp2.status == 200
    @test length(r.dapr.object_store) == 1

    @test fetch_status(r.dapr, job_id; timeout=1.0)[2].status == Jugsaw.Server.succeeded

    # call functions not exist
    fcall2 = JugsawIR.julia2adt(JugsawIR.Call(:sinx, (0.5,), (;)))[1]
    job_id = string(Jugsaw.uuid4())
    req = Client.new_request_obj(context, Val(:job), job_id, fcall2)
    resp1 = Server.job_handler(r, req)
    @test resp1.status == 400
    @test length(r.dapr.object_store) == 1

    @test fetch_status(r.dapr, job_id; timeout=1.0)[2].status == Jugsaw.Server.failed

    # trigger the bug
    fcall3 = JugsawIR.julia2adt(JugsawIR.Call(:buggy, (-0.5,), (;)))[1]
    job_id = string(Jugsaw.uuid4())
    req = Client.new_request_obj(context, Val(:job), job_id, fcall3)
    resp1 = Server.job_handler(r, req)
    @test resp1.status == 200
    req = Client.new_request_obj(context, Val(:fetch), job_id)
    resp2 = Server.fetch_handler(r, req)
    @test resp2.status == 400
    @test length(r.dapr.object_store) == 1

    # query status
    @test fetch_status(r.dapr, job_id; timeout=1.0)[2].status == Jugsaw.Server.failed
end