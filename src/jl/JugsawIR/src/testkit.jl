function test_twoway(obj::T, demo::T=obj) where T
    adt, typeadt = julia2adt(obj)
    res = adt2julia(adt, demo)
    return obj === res || obj == res || obj ≈ res
end

