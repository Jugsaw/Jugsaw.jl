###################### IR 2 Tree
const jp = Lark(read(joinpath(@__DIR__, "jugsawir.lark"), String),parser="lalr",lexer="contextual", start="object")
ir2tree(str::String) = Lerche.parse(jp, str)
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
            "object" || "number" || "string" => tree2adt(t.children[])
            "true" => true
            "false" => false
            "null" => nothing
            "list" => JugsawADT.Vector(tree2adt.(t.children))
            "genericobj1" => buildobj("Core.Any", tree2adt.(t.children[1].children))
            "genericobj2" => buildobj(tree2adt(t.children[1]), tree2adt.(t.children[2].children))
            "genericobj3" => buildobj(tree2adt(t.children[2]), tree2adt.(t.children[1].children))
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
buildobj(type::String, fields::Vector) = JugsawADT.Object(type, fields)

###################### ADT to IR
adt2ir(x) = JSON3.write(_adt2ir(x))
function _adt2ir(x)
    @match x begin
        JugsawADT.Object(type, fields) => begin
            _makedict(type, Any[_adt2ir(v) for v in fields])
        end
        JugsawADT.Vector(storage) => _adt2ir.(storage)
        ::DirectlyRepresentableTypes || ::UndefInitializer => x
        _ => error("type can not be casted to IR, got: $x of type $(typeof(x))")
    end
end
function _makedict(type::String, fields::Vector{Any})
    return Dict("type"=>type, "fields"=>fields)
end

##################### Interfaces
function julia2ir(obj)
    obj, tt = julia2adt(obj)
    # TODO: remove json!
    adt2ir(obj), adt2ir(tt)
end

######################## ir2adt
const ir2adt = tree2adt ∘ ir2tree