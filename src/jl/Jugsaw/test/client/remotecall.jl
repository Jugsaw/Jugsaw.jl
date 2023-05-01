using Test, Jugsaw, JugsawIR, Jugsaw.Client

@testset "local call" begin
    path = joinpath(dirname(@__DIR__), "testapp")
    r = LocalHandler(path, ()->open(f->write(f, "2"), joinpath(path, "result.json"), "w"))
    app = request_app(r, :testapp)
    @test app isa Client.App
    @test_throws ErrorException @call r sin(2.0)
    @test 2 == (@call r app.sin(2.0;))()
end

@testset "server-client" begin
    #t = HTTP.serve(router, ip"127.0.0.1", 8080, is_async=true)
end