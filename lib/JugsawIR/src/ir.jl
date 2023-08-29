###################### IR 2 Tree
ir2tree(str::String) = Lerche.parse(jp, str)
cli2tree(str::String) = Lerche.parse(jcli, str)
"""
$(TYPEDSIGNATURES)

Convert Jugsaw IR to julia object, given a demo object as a reference. Please check [`julia2ir`](@ref) for the inverse map.

### Examples
```jldoctest; setup=:(using JugsawIR)
julia> JugsawIR.ir2julia("{\\"fields\\" : [3, 4]}", 1+2im)
3 + 4im
```
"""
function ir2julia(str::String, demo)
    tree = ir2tree(str)
    adt = tree2adt(tree)
    return adt2julia(adt, demo)
end

AbstractTrees.children(t::Lerche.Tree) = t.children
function AbstractTrees.printnode(io::IO, t::Lerche.Tree)
	print(io, t.data)
end
function AbstractTrees.printnode(io::IO, t::Lerche.Token)
    print(io, t.value)
end

##################### Tree to ADT
function tree2adt(t)
    @match t begin
        ::Tree => @match t.data begin
            "expr" || "number" || "string" => tree2adt(t.children[])
            "true" => true
            "false" => false
            "null" => nothing
            "object" => JugsawExpr(:object, tree2adt.(t.children))
            "untyped" => JugsawExpr(:untyped, tree2adt.(t.children))
            "list" => JugsawExpr(:list, tree2adt.(t.children))
            "call" => JugsawExpr(:call, tree2adt.(t.children))
        end
        ::Token => begin
            try
                return Meta.parse(t.value)
            catch e
                # wield parsing error when handling interpolated strings
                # TODO: fix this problem!
                Base.showerror(stdout, e)
                println(stdout)
                @info "try fixing! error str: $(t.value)"
                return Meta.parse(replace(t.value, "\$"=>"\\\$"))
            end
        end
    end
end
buildobj(type::String, fields::Vector) = JugsawExpr(:object, type, fields)

function clitree2julia(t, @nospecialize(demo::T)) where T
    @match t begin
        ::Tree => @match t.data begin
            "expr" || "number" || "string" => clitree2julia(t.children[], demo)
            "true" => begin
                @assert demo isa Bool
                true
            end
            "false" => begin
                @assert demo isa Bool
                false
            end
            "null" => begin
                @assert demo isa Nothing || demo isa Missing || demo isa UndefInitializer
                demo
            end
            "object" => begin
                @match demo begin
                    # treat type specially
                    ::Storage => T(clitree2julia.(t.children, Ref(demoofelement(demo.storage))))
                    _ => begin
                        if demo isa Type
                            demo
                        else
                            _x = native2jugsaw(demo)
                            vals = [clitree2julia(t.children[i], getfield(_x, fn)) for (i, fn) in enumerate(fieldnames(typeof(_x))) if isdefined(_x, fn)]
                            obj = Core.eval(@__MODULE__, Expr(:new, typeof(_x), Any[:($vals[$i]) for i=1:length(vals)]...))
                            jugsaw2native(obj, demo)
                        end
                    end
                end
            end
            "call" => begin
                SEP = findfirst(x->x.data == "kwarg", t.children)
                if SEP === nothing
                    fname, args, kwargs = t.children[1], t.children[2:end], empty(t.children)
                else
                    fname, args, kwargs = t.children[1], t.children[2:SEP-1], t.children[SEP:end]
                end
                # function name
                fn = demo.fname
                # args
                ar = (clitree2julia.(args, demo.args)...,)
                # keyword args
                dict = Dict([Symbol(x.children[1].children[].value)=>x.children[2] for x in kwargs])
                if any(x->x∉keys(demo.kwargs), keys(dict))
                    throw(ArgumentError("Invalid keyword arguments, got $(keys(dict)), should be a subset of $(keys(demo.kwargs))"))
                end
                kw = (; [(k, haskey(dict, k) ? clitree2julia(dict[k], v) : v) for (k, v) in pairs(demo.kwargs)]...)
                return Call(fn, ar, kw)
            end
            # symbol and kwarg are not parsed directly.
        end
        ::Token => begin
            parsed = try
                Meta.parse(t.value)
            catch e
                # wield parsing error when handling interpolated strings
                # TODO: fix this problem!
                Base.showerror(stdout, e)
                println(stdout)
                @info "try fixing! error str: $(t.value)"
                Meta.parse(replace(t.value, "\$"=>"\\\$"))
            end
            @match demo begin
                ::String => T(parsed)
                ::Char => T(parsed[1])  # Char is represented as string Token
                ::Union{Int16, Int32, Int64, Int128, Float16, Float32, Float64} => T(parsed)
                _ => error("Invalid primitive data type, got: $(typeof(demo))")
            end
        end
    end
end

###################### ADT to IR
adt2ir(x) = JSON3.write(_adt2ir(x))
function _adt2ir(x)
    @match x begin
        ::JugsawExpr => Any[x.head, _adt2ir.(x.args)...]
        ::DirectlyRepresentableTypes || ::UndefInitializer => x
        _ => error("type can not be casted to IR, got: $x of type $(typeof(x))")
    end
end

##################### Interfaces
"""
$(TYPEDSIGNATURES)

Convert julia object to Jugsaw IR and a type table, where the type table is a special Jugsaw IR that stores the type definitions.
Please check [`ir2julia`](@ref) for the inverse map.

### Examples
```jldoctest; setup=:(using JugsawIR)
julia> ir, typetable = JugsawIR.julia2ir(1+2im);

julia> ir
"{\\"fields\\":[1,2],\\"type\\":\\"Base.Complex{Core.Int64}\\"}"
```
"""
function julia2ir(obj)
    obj, tt = julia2adt(obj)
    # TODO: remove json!
    adt2ir(obj), adt2ir(tt)
end

######################## ir2adt
const ir2adt = tree2adt ∘ ir2tree
