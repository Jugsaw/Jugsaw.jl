using Jugsaw.Universe
using Jugsaw.JugsawIR
import Jugsaw
using Test

@testset "gradio types" begin
    @enum Fruit APPLE ORANGE GRAPE
    for x in [
        MultiChoice([APPLE, GRAPE]),
        Code("julia", "x = 4"),
        Color("#FFAD45"),
        Dataframe(["name", "age"], [("Jinguo", 33), ("Jun", 32)]),
        Choice(APPLE),
        File("七里香.mp3", rand(UInt8, 100)),
        RGBImage(rand(3, 100, 100))
        ]
        js = json4(x)
        obj = parse4(js, mod=@__MODULE__)
        @test x == obj
    end
end