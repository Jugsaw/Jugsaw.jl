using Test
using Jugsaw, JugsawIR
using HTTP, JugsawIR.JSON3, URIs
using Jugsaw.Server, Jugsaw.Client

@testset "in memory event" begin
    dapr = InMemoryEventService()
    job_id = string(Jugsaw.uuid4())
    @test get_timeout() == 15.0
    @test Server.get_query_interval() == 0.1

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
    app = Jugsaw.APP; empty!(app)
    @register testapp begin
        sin(cos(0.5))::Float64
        cos(0.5)::Float64
    end
    dapr = InMemoryEventService()
    r = AppRuntime(app, dapr)
    @test r isa AppRuntime

    # simple call
    job_id = string(Jugsaw.uuid4())
    fcall = JugsawIR.Call(sin, (0.5,), (;))
    adt = JugsawIR.write_object(JugsawIR.Call(sin, (0.5,), (;)))
    obj = JugsawIR.read_object(adt, fcall)
    job = Job(job_id, time(), "jugsaw", 1.0, Call(sin, obj.args, obj.kwargs))
    Jugsaw.Server.submitjob!(r, job)
    st, res = load_object(dapr, job_id, fevalself(fcall); timeout=1.0)
    @test res ≈ sin(0.5)
    @test fetch_status(dapr, job_id; timeout=1.0)[2].status == Jugsaw.Server.succeeded
end

@testset "app runtime error" begin
    # error call
    function buggy(x)
        if x < 0
            error("you did not catch me!")
        end
    end
    app = Jugsaw.APP; empty!(app)
    dapr = InMemoryEventService()
    @register testapp sin(cos(0.5))::Float64
    @register testapp buggy(0.5)
    r = AppRuntime(app, dapr)

    job_id = string(Jugsaw.uuid4())
    fcall = JugsawIR.Call(buggy, (1.0,), (;))
    adt1 = JugsawIR.write_object(JugsawIR.Call(buggy, (1.0,), (;)))
    # normal call
    obj = JugsawIR.read_object(adt1, fcall)
    job = Job(job_id, time(), "jugsaw", 1.0, Call(buggy, obj.args, obj.kwargs))
    Jugsaw.Server.submitjob!(r, job)
    st, res = load_object(dapr, job_id, fevalself(fcall); timeout=1.0)
    @test fetch_status(dapr, job_id; timeout=1.0)[2].status == Jugsaw.Server.succeeded
    # trigger error
    fcall = JugsawIR.Call(buggy, (-1.0,), (;))
    adt2 = JugsawIR.write_object(JugsawIR.Call(buggy, (-1.0,), (;)))
    obj = JugsawIR.read_object(adt2, fcall)
    job = Job(job_id, time(), "jugsaw", 1.0, Call(buggy, obj.args, obj.kwargs))
    Jugsaw.Server.submitjob!(r, job)
    st, res = load_object(dapr, job_id, nothing; timeout=1.0)
    @test fetch_status(dapr, job_id; timeout=1.0)[2].status == Jugsaw.Server.failed
end

@testset "job handler" begin
    # create an app
    app = Jugsaw.APP; empty!(app)
    dapr = InMemoryEventService()
    @register testapp sin(cos(0.5))::Float64
    r = AppRuntime(app, dapr)
    context = Client.ClientContext()

    # luanch and fetch a job
    demo = JugsawIR.Call(sin, (0.5,), (;))
    fcall = Call("sin", (0.5,), (;))
    job_id = string(Jugsaw.uuid4())
    req = Jugsaw.Client.new_request_obj(context, Val(:job), job_id, fcall; maxtime=10.0)
    req.context[:params] = Dict("fname"=>"sin")
    resp1 = Jugsaw.Server.job_handler(r, req)
    # fetch interface
    req = Jugsaw.Client.new_request_obj(context, Val(:fetch), job_id)
    resp2 = Server.fetch_handler(r, req)
    @test resp1.status == 200
    @test resp2.status == 200
    @test fetch_status(r.dapr, job_id; timeout=1.0)[2].status == Jugsaw.Server.succeeded

    # load object
    obj = JugsawIR.read_object(String(resp2.body), 0.0)
    @test obj ≈ sin(0.5)
end

@testset "parse fcall" begin
    app = Jugsaw.APP; empty!(app)
    @register testapp sin(cos(0.5))::Float64
    path = joinpath(@__DIR__, "testapp")
    # saving demos
    Jugsaw.save_demos(path, app)
    @test isfile(joinpath(path, "demos.json"))
    # loading demos
    newdemos = Jugsaw.load_demos_from_dir(path)
    @test length(newdemos.app.method_demos) == length(app.method_demos)

    # empty!
    empty!(app)
    @test Jugsaw.nfunctions(app) == 0

    # register a type function
    @register testapp Tuple([1, 2, 3]) == (1, 2, 3)
    struct A end
    @register testapp A()
    @test Jugsaw.nfunctions(app) == 2
    demo = first(app.method_demos)[2]
    @test feval(demo.fcall) == A()
    demo = app.method_demos[app.method_names[1]]
    @test fevalself(demo.fcall) == (1, 2, 3)
end