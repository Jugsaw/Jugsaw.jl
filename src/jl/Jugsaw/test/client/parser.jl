using Test, Jugsaw.Client
using JugsawIR
using Markdown

@testset "decode_fname" begin
    @test Client.decode_fname("Base.#cos") == :cos
    @test Client.decode_fname("Test.Base.#cos") == :cos
    @test Client.decode_fname("Test.Base.cos") == :cos
end

@testset "parse" begin
    for x in [3, true, false, nothing, "##"]
        obj, type = JugsawIR.json4(x)
        #res = JugsawIR.Lerche.parse(Client.jpt, obj)
        res = Client.load_obj(JugsawIR.Lerche.parse(JugsawIR.jp, obj), JugsawIR.TypeTable())
        @test res == x
    end

    app = Client.load_demos_from_dir(joinpath(dirname(@__DIR__), "testapp"))
    println(app)
    @test app.cos[].second isa Client.Demo
    print(app.cos[].second.meta["docstring"])
    @test app.cos[].second.meta["docstring"] isa String
    #Client.print_app(app)
end