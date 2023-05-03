# JugsawIR code -> Lerche.Tree -> JugsawADT <-> Julia
#       ↑                            ↓
#       <-----------------------------
using Expronicon
using Expronicon.ADT: @adt

@adt JugsawADT begin
    struct Object
        type::String
        fields::Vector
    end
    struct Call
        fname::String
        args::Vector
        kwargnames::Vector{String}
        kwargvalues::Vector
    end
    struct Type
        name::String
        fieldnames::Vector
        fieldtypes::Vector
    end
end

#=
obj = JugsawADT.Object("T", [1, "4"])
ex = JugsawADT.Call("T", [1, "4"], ["x"=>4, "y"=>obj])

using MLStyle
ex = 2
@match ex begin
    JugsawADT.Object(type, fields) => "find object: $type, $fields"
    JugsawADT.Call(fname, args, kwargs) => "find call: $args, $kwargs"
    _ => ex
end
=#

##################### load object without demo
function load_obj(t)
    @match t begin
        ::Tree => @match t.data begin
            "object" || "number" || "string" => load_obj(t.children[])
            "true" => true
            "false" => false
            "null" => nothing
            "list" => load_obj.(t.children)
            "genericobj1" => error("type name not specified!")
            "genericobj2" => buildobj(load_obj(t.children[1]), load_obj.(t.children[2].children))
            "genericobj3" => buildobj(load_obj(t.children[2]), load_obj.(t.children[1].children))
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
        :(JugsawIR.JugsawFunctionCall) => JugsawADT.Call(fields...)
        :(Core.Array) => reshape(fields[2], fields[1]...)
        :(Base.Dict) => Dict(zip(fields[1], fields[2]))
        :(Base.Enum) => error("I do not want to support it!")
        :(Core.Tuple) => (fields...,)
        _ => Object(type, fields)
    end
end

############## construct an object from the Lerche.Tree and JugsawADT demo.
# note JugsawADT demo parsing does not following the rule for the generic types.
function construct_object(t::Lerche.Tree, demo::JugsawADT)
    @match demo begin
        JugsawADT.Object(type, fields) => begin
            # there may be a first field "type".
            _newfields = _getfields(t)
            newfields = Any[fromtree(val, demoval) for (val, demoval) in zip(_newfields, fields)]
            JugsawADT.Object(type, newfields)
        end
        JugsawADT.Call(fname, args, kwargnames, kwargvalues) => begin
            fname, _newargs, _newkwargs = _getfields(t)
            _newkwargvalues = _getfields(t)[2]
            newargs = Any[fromtree(val, demoval) for (val, demoval) in zip(_newargs, args)]
            newkwargvalues = Any[fromtree(val, demoval) for (val, demoval) in zip(_newkwargvalues, kwargvalues)]
            JugsawADT.Call(fname, newargs, kwargnames, newkwargvalues)
        end
        JugsawADT.Type(name, fieldnames, fieldtypes) => begin
            JugsawADT.Type(_getfields(t)...)
        end
    end
end

###################### Parse Jugsaw ADT to JugsawIR code
function todict!(x::JugsawADT, tt::TypeTable)
    def!(tt::TypeTable, x.type, x.fieldnames, (todict!.(x.fields, Ref(tt))...,))
end

