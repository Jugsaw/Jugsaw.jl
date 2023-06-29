function test_twoway(obj, demo=obj)
    adt, typeadt = julia2adt(obj)
    res = adt2julia(adt, demo)
    return isthesame(obj, res)
end

function isthesame(target, res)
    return target === res || target == res || have_same_type_and_fields(target, res) || target ≈ res
end

function have_same_type_and_fields(target, res)
    return typeof(target) == typeof(res) && all(fn -> (!isdefined(target, fn) && !isdefined(res, fn)) || isthesame(getfield(target, fn), getfield(res, fn)), fieldnames(typeof(target)))
end

