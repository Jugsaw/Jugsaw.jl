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
            "list" => tree2adt.(t.children)
            "genericobj1" => error("type name not specified!")
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
function buildobj(type::String, fields::Vector)
    @match Meta.parse(type) begin
        :(Jugsaw.TypeAsFunction{$type}) => buildobj(type, fields)
        :($type{$(args...)}) => buildobj(type, fields)
        :(Core.DataType) => JugsawADT.Type(fields...)
        :(JugsawIR.Call) => JugsawADT.Call(fields...)
        :(Core.Array) => reshape(fields[2], fields[1]...)
        :(Base.Dict) => Dict(zip(fields[1], fields[2]))
        :(Base.Enum) => error("I do not want to support it!")
        :(Core.Tuple) => (fields...,)
        _ => Object(type, fields)
    end
end

############## construct an object from the Lerche.Tree and JugsawADT demo.
# note JugsawADT demo parsing does not following the rule for the generic types.
# function construct_object(t::Lerche.Tree, demo::JugsawADT)
#     @match demo begin
#         JugsawADT.Object(type, fields) => begin
#             # there may be a first field "type".
#             _newfields = _getfields(t)
#             newfields = Any[tree2julia(val, demoval) for (val, demoval) in zip(_newfields, fields)]
#             JugsawADT.Object(type, newfields)
#         end
#         JugsawADT.Call(fname, args, kwargnames, kwargvalues) => begin
#             fname, _newargs, _newkwargs = _getfields(t)
#             _newkwargvalues = _getfields(t)[2]
#             newargs = Any[tree2julia(val, demoval) for (val, demoval) in zip(_newargs, args)]
#             newkwargvalues = Any[tree2julia(val, demoval) for (val, demoval) in zip(_newkwargvalues, kwargvalues)]
#             JugsawADT.Call(fname, newargs, kwargnames, newkwargvalues)
#         end
#         JugsawADT.Type(name, fieldnames, fieldtypes) => begin
#             JugsawADT.Type(_getfields(t)...)
#         end
#     end
# end

###################### ADT to IR
adt2ir(x) = JSON3.write(_adt2ir(x))
function _adt2ir(x)
    @show x
    @match x begin
        JugsawADT.Object(type, fields) => begin
            _makedict(type, Any[adt2ir(v) for v in fields])
        end
        JugsawADT.Call(fname, args, kwargnames, kwargvalues) => begin
            _makedict(type2str(Call), Any[fname, Any[adt2ir(arg) for arg in args], kwargnames, Any[adt2ir(arg) for arg in kwargvalues]])
        end
        JugsawADT.Type(name, fieldnames, fieldtypes) => begin
            _makedict(type2str(DataType), Any[name, fieldnames, fieldtypes])
        end
        ::DirectlyRepresentableTypes => x
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

