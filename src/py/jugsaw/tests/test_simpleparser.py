from jugsaw import jtp, jp, JugsawType, JugsawObject, Symbol

def test_jp():
    res = jp.parse("""
            {"type" : "Jugsaw.People{Core.Int}", "values" : [32], "fields" : ["age"]}
            """)
    print(res)
    assert res == JugsawObject(JugsawType("Jugsaw", "People", [JugsawType("Core", "Int", None)]), [32], ["age"])
    res = jp.parse("""
            {"type":"Jugsaw.TP", "values":[], "fields":[]}
            """)
    print(res)
    assert res == JugsawObject(JugsawType("Jugsaw", "TP", None), [], [])