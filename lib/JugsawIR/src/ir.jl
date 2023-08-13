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
