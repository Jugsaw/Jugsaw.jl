using JugsawIR: jp
using Lerche
using Test

@testset "object" begin
    res = Lerche.parse(jp, """{"type" : "Jugsaw.People{Core.Int}", "fields" : [32]}""")
    print(res)
    #@test res == JugsawObject(JugsawType("Jugsaw", "People", [JugsawType("Core", "Int", None)]), [32], ["age"])
    res = Lerche.parse(jp, """{"type":"Jugsaw.TP", "fields":[]}""")
    print(res)
    
    res = Lerche.parse(jp, """{"fields":[]}""")
    print(res)
    #@test res == JugsawObject(JugsawType("Jugsaw", "TP", None), [], [])
end