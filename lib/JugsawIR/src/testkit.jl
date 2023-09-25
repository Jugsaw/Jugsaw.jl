function test_twoway(obj, demo=obj)
    ir = write_object(obj)
    res = read_object(ir, typeof(demo))
    return isthesame(obj, res)
end

function isthesame(target, res)
    return target === res || target == res || have_same_type_and_fields(target, res) || target ≈ res
end

function have_same_type_and_fields(target, res)
    return typeof(target) == typeof(res) && all(fn -> (!isdefined(target, fn) && !isdefined(res, fn)) || isthesame(getfield(target, fn), getfield(res, fn)), fieldnames(typeof(target)))
end

