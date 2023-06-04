using Test
using Jugsaw, JugsawIR
using HTTP, JugsawIR.JSON3, URIs
using Jugsaw.Server
using Jugsaw.Client

@testset "routes" begin
    context = Client.ClientContext()
    app = AppSpecification(:testapp)
    dapr = FileEventService(joinpath(@__DIR__, ".daprtest"))
    @register app sin(cos(0.5))::Float64
    ar = AppRuntime(app, dapr)
    r = Jugsaw.Server.get_router(Jugsaw.Server.LocalRoute(), ar)
    # services
    @test JSON3.read(r(Jugsaw.Client.new_request_obj(context, Val(:healthz)))).status == "OK"

    # demos
    @test r(Jugsaw.Client.new_request_obj(context, Val(:demos))).status == 200

    # api
    req = Jugsaw.Client.new_request_obj(context, Val(:api), JugsawIR.Call("sin", (0.5,), (;)), "JuliaLang")
    @test r(req).status == 200
    # language not defined
    req = Jugsaw.Client.new_request_obj(context, Val(:api), JugsawIR.Call("sin", (0.5,), (;)), "Julia")
    @test r(req).status == 400
    
    # subscribe
    @test_broken r(HTTP.Request("GET", "/dapr/subscribe")).status == 200

    # launch a job
    job_id = string(Jugsaw.uuid4())
    req = Jugsaw.Client.new_request_obj(context, Val(:job), job_id, JugsawIR.Call(sin, (0.5,), (;)))
    ret = r(req)
    @test ret.status == 200

    # fetch result
    req = Jugsaw.Client.new_request_obj(context, Val(:fetch), job_id)
    ret = r(req)
    @test ret.status == 200
end

