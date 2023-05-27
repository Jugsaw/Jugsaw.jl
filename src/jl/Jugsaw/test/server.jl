using Test
using Jugsaw, JugsawIR
using HTTP, JugsawIR.JSON3, URIs
using Jugsaw.Server

@testset "file event service" begin
    dapr = FileEventService(joinpath(@__DIR__, ".daprtest"))
    mkpath(dapr.save_dir)
    @test get_timeout(dapr) == 1.0

    job_id = string(Jugsaw.uuid4())

    # status updated
    status = JobStatus(id=job_id, status=Jugsaw.Server.succeeded)
    publish_status(dapr, status)
    @test fetch_status(dapr, job_id; timeout=1.0) == (:ok, status)

    # another status updated
    status = JobStatus(id=job_id, status=Jugsaw.Server.failed)
    publish_status(dapr, status)
    @test fetch_status(dapr, job_id; timeout=1.0) == (:ok, status)

    # incorrect id triggers the timeout
    @test fetch_status(dapr, "asfd"; timeout=1.0) == (:timed_out, nothing)

    save_object(dapr, job_id, Dict("x"=>42))
    st, d = load_object(dapr, job_id, Dict("y"=>4); timeout=1.0)
    @test st == :ok
    @test d == Dict("x"=>42)
end

@testset "in memory event" begin
    dapr = InMemoryEventService()
    @test get_timeout(dapr) == 0.0
    job_id = string(Jugsaw.uuid4())

    # status updated
    status = JobStatus(id=job_id, status=Jugsaw.Server.succeeded)
    publish_status(dapr, status)
    @test fetch_status(dapr, job_id; timeout=1.0) == (:ok, status)

    # another status updated
    status = JobStatus(id=job_id, status=Jugsaw.Server.failed)
    publish_status(dapr, status)
    @test fetch_status(dapr, job_id; timeout=1.0) == (:ok, status)

    # incorrect id triggers the timeout
    @test fetch_status(dapr, "asfd"; timeout=1.0) == (:timed_out, nothing)

    save_object(dapr, job_id, Dict("x"=>42))
    st, d = load_object(dapr, job_id, Dict("y"=>4); timeout=1.0)
    st, dir = load_object_as_ir(dapr, job_id; timeout=1.0)
    @test st == :ok
    @test d == Dict("x"=>42)
    @test dir isa String
end

@testset "app runtime" begin
    app = AppSpecification(:testapp)
    @register app sin(cos(0.5))::Float64
    dapr = FileEventService(joinpath(@__DIR__, ".daprtest"))
    r = AppRuntime(app, dapr)
    @test r isa AppRuntime

    # simple call
    job_id = string(Jugsaw.uuid4())
    adt, = JugsawIR.julia2adt(JugsawIR.Call(sin, (0.5,), (;)))
    jobspec = JobSpec(job_id, round(Int, time()), "jugsaw", 1.0, adt.fields...)
    job = addjob!(r, jobspec)
    st, res = load_object(dapr, job_id, job.demo.result; timeout=1.0)
    @test res ≈ sin(0.5)
    @test fetch_status(dapr, job_id; timeout=1.0)[2].status == Jugsaw.Server.succeeded

    # nested call
    job_id = string(Jugsaw.uuid4())
    adt1, = JugsawIR.julia2adt(JugsawIR.Call(cos, (0.7,), (;)),)
    adt = JugsawIR.JugsawADT.Object("JugsawIR.Call",
        ["sin", JugsawIR.JugsawADT.Object(JugsawIR.type2str(Tuple{Float64}), [adt1]), JugsawIR.julia2adt((;))[1]])
    # fix adt
    jobspec = JobSpec(job_id, round(Int, time()), "jugsaw", 1.0, adt.fields...)
    job = addjob!(r, jobspec)
    st, res = load_object(dapr, job_id, job.demo.result; timeout=1.0)
    @test res ≈ sin(cos(0.7))
    @test fetch_status(dapr, job_id; timeout=1.0)[2].status == Jugsaw.Server.succeeded
end

@testset "app runtime error" begin
    # error call
    function buggy(x)
        if x < 0
            error("you did not catch me!")
        end
    end
    app = AppSpecification(:testapp)
    dapr = FileEventService(joinpath(@__DIR__, ".daprtest"))
    @register app sin(cos(0.5))::Float64
    @register app buggy(0.5)
    r = AppRuntime(app, dapr)

    job_id = string(Jugsaw.uuid4())
    adt1, = JugsawIR.julia2adt(JugsawIR.Call(buggy, (1.0,), (;)))
    # normal call
    jobspec = JobSpec(job_id, round(Int, time()), "jugsaw", 1.0, adt1.fields...)
    job = addjob!(r, jobspec)
    st, res = load_object(dapr, job_id, job.demo.result; timeout=1.0)
    @test fetch_status(dapr, job_id; timeout=1.0)[2].status == Jugsaw.Server.succeeded
    # trigger error
    adt2, = JugsawIR.julia2adt(JugsawIR.Call(buggy, (-1.0,), (;)))
    jobspec = JobSpec(job_id, round(Int, time()), "jugsaw", 1.0, adt2.fields...)
    job = addjob!(r, jobspec)
    st, res = load_object(dapr, job_id, job.demo.result; timeout=1.0)
    @test fetch_status(dapr, job_id; timeout=1.0)[2].status == Jugsaw.Server.failed
end

@testset "job handler" begin
    # create an app
    app = AppSpecification(:testapp)
    dapr = FileEventService(joinpath(@__DIR__, ".daprtest"))
    @register app sin(cos(0.5))::Float64
    r = AppRuntime(app, dapr)

    # luanch and fetch a job
    fcall = JugsawIR.Call(:sin, (0.5,), (;))
    job_id = string(Jugsaw.uuid4())
    req = Jugsaw.Client.new_request_obj(Val(:job), job_id, fcall; maxtime=10.0)
    resp1 = Jugsaw.Server.job_handler(r, req)
    # fetch interface
    req = Jugsaw.Client.new_request_obj(Val(:fetch), job_id)
    resp2 = Server.fetch_handler(r, req)
    @test resp1.status == 200
    @test resp2.status == 200
    @test fetch_status(r.dapr, job_id; timeout=1.0)[2].status == Jugsaw.Server.succeeded

    # load object
    obj = JugsawIR.ir2adt(JSON3.read(resp2.body).data)
    @test obj ≈ sin(0.5)
end

@testset "code handler" begin
    app = AppSpecification(:testapp)
    dapr = FileEventService(joinpath(@__DIR__, ".daprtest"))
    @register app sin(cos(0.5))::Float64

    req = Jugsaw.Client.new_request_obj(Val(:api), JugsawIR.Call("sin", (0.5,), (;)), "JuliaLang")
    req.context[:params] = Dict("lang"=>"JuliaLang")
    ret = Jugsaw.Server.code_handler(req, app)
    @test ret.status == 200
    @test JSON3.read(ret.body).code isa String
    @show JSON3.read(ret.body).code

    req = Jugsaw.Client.new_request_obj(Val(:api), JugsawIR.Call("sinx", (0.5,), (;)), "JuliaLang")
    req.context[:params] = Dict("lang"=>"JuliaLang")
    ret = Jugsaw.Server.code_handler(req, app)
    @test ret.status == 400
end

@testset "routes" begin
    app = AppSpecification(:testapp)
    dapr = FileEventService(joinpath(@__DIR__, ".daprtest"))
    @register app sin(cos(0.5))::Float64
    ar = AppRuntime(app, dapr)
    r = Jugsaw.Server.get_router(ar)
    # services
    @test JSON3.read(r(Jugsaw.Client.new_request_obj(Val(:healthz)))).status == "OK"

    # demos
    @test r(Jugsaw.Client.new_request_obj(Val(:demos))).status == 200

    # api
    req = Jugsaw.Client.new_request_obj(Val(:api), JugsawIR.Call("sin", (0.5,), (;)), "JuliaLang")
    @test r(req).status == 200
    # language not defined
    req = Jugsaw.Client.new_request_obj(Val(:api), JugsawIR.Call("sin", (0.5,), (;)), "Julia")
    @test r(req).status == 400
    
    # subscribe
    @test_broken r(HTTP.Request("GET", "/dapr/subscribe")).status == 200

    # launch a job
    job_id = string(Jugsaw.uuid4())
    req = Jugsaw.Client.new_request_obj(Val(:job), job_id, JugsawIR.Call(sin, (0.5,), (;)))
    ret = r(req)
    @test ret.status == 200

    # fetch result
    req = Jugsaw.Client.new_request_obj(Val(:fetch), job_id)
    ret = r(req)
    @test ret.status == 200
end

@testset "parse fcall" begin
    app = AppSpecification(:testapp)
    @register app sin(cos(0.5))::Float64
    path = joinpath(@__DIR__, "testapp")
    # saving demos
    Jugsaw.save_demos(path, app)
    @test isfile(joinpath(path, "demos.json"))
    # loading demos
    newdemos, newtypes = Jugsaw.load_demos_from_dir(path, app)
    @test newdemos == app
    @test newtypes isa Jugsaw.JugsawIR.TypeTable

    # empty!
    empty!(app)
    @test Jugsaw.nfunctions(app) == 0

    # register a type function
    @register app Tuple([1, 2, 3]) == (1, 2, 3)
    struct A end
    @register app A()
    @test Jugsaw.nfunctions(app) == 2
    demo = first(first(app.method_demos)[2])
    @test feval(demo.fcall) == A()
    demo = app.method_demos[app.method_names[1]][1]
    @test fevalself(demo.fcall) == (1, 2, 3)
end