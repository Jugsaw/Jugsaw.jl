using Test, Jugsaw.Client
using JugsawIR

@testset "parse" begin
    tt = Client.load_types_from_file(joinpath(dirname(joinpath(@__DIR__)), "testapp", "types.json"))
    @test tt isa JugsawIR.TypeTable

    for x in [3, true, false, nothing, "##"]
        obj, type = JugsawIR.json4(x)
        #res = JugsawIR.Lerche.parse(Client.jpt, obj)
        res = Client.fromtree(JugsawIR.Lerche.parse(JugsawIR.jp, obj))
        @test res == x
    end
end

load_demos_from_dir(dirname::String)