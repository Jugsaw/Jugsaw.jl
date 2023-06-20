abstract type AbstractLang end
struct Julia <: AbstractLang end
struct Python <: AbstractLang end
struct Javascript <: AbstractLang end

"""
    generate_code(lang, endpoint::String, appname::Symbol, fcall::JugsawADT, democall::JugsawIR.Call)

Generate code for target language.

### Arguments
* `lang` can be a string or an [`AbstractLang`](@ref) instance that specifies the target language.
Please use `subtypes(AbstractLang)` for supported client languages.
* `endpoint` is the url for service provider, e.g. it can be [https://www.jugsaw.co](https://www.jugsaw.co).
* `appname` is the application name.
* `fcall` is a [`JugsawADT`](@ref) that specifies the function call.
* `typetable` is a [`TypeTable`](@ref) instance with the type definitions.
"""
function generate_code(lang::String, endpoint, appname, fcall, typetable::JugsawADT)
    @assert fcall.typename == "JugsawIR.Call"
    if isempty(endpoint)
        @warn("The endpoint of this server is not set properly.")
    end
    tt = JugsawIR.adt2julia(typetable, JugsawIR.demoof(JugsawIR.TypeTable))
    pl = if lang == "Julia"
        Julia()
    elseif lang == "Python"
        Python()
    elseif lang == "Javascript"
        Javascript()
    else
        return error("Client langauge not defined, got: $lang")
    end
    return _generate_code(pl, endpoint, appname, fcall, tt)
end

# converting IR to different languages
function _generate_code(::Julia, endpoint::String, appname::Symbol, fcall::JugsawADT, typetable::TypeTable)
    fname, fargs, fkwargs = fcall.fields
    args = join([adt2client(Julia(), arg) for arg in fargs.fields],", ")
    kws = typetable.defs[fkwargs.typename].fieldnames
    kwargs = join(["$key = $(adt2client(Julia(), arg))" for (key, arg) in zip(aslist(kws), fkwargs.fields)],", ")
    code = """using Jugsaw.Client
app = request_app(ClientContext(; endpoint=$(repr(endpoint)), :$(appname)))
app.$fname($args; $kwargs)
"""
    return code
end
function adt2client(lang::Julia, x)
    @match x begin
        ###################### Generic Compsite Types ######################
        ::JugsawADT.Object => begin
            if startswith(x.typename, "JugsawIR.JArray")
                join([adt2client(lang, elem) for elem in x.fields[2].storage], ", ")
            elseif startswith(x.typename, "JugsawIR.JDict")
                kvpairs = join(["$(adt2client(lang, k)) => $(adt2client(lang, v))" for (k, v) in zip(x.fields[1], x.fields[2])], ", ")
                "Dict($kvpairs)"
            elseif startswith(x.typename, "JugsawIR.JEnum")
                repr(x)
            else
                vals = [adt2client(lang, field) for (field, fn) in zip(t.fields, fieldnames(T)) if isdefined(demo, fn)]
                "(" * join(vals, ", ") * ")"
            end
        end
        ::JugsawADT.Vector => join([adt2client(lang, v) for v in x], ", ")
        ##################### Primitive types ###################
        _ => repr(x)
    end
end

function _generate_code(::Python, endpoint::String, appname::Symbol, fcall::JugsawADT, typetable::TypeTable)
    fname, fargs, fkwargs = fcall.fields
    args = join([adt2client(Python(), arg) for arg in fargs],", ")
    kws = typetable.defs[fkwargs.typename].fieldnames
    kwargs = join(["$key = $(adt2client(Python(), arg))" for (key, arg) in zip(kws, fkwargs)],", ")
    code = """import jugsaw, numpy
app = jugsaw.request_app(jugsaw.ClientContext(; endpoint=$(repr(endpoint))), $(repr(string(appname))))
app.$fname($args, $kwargs)
"""
    return code
end
# We use tuple for objects
# numpy array for Array
# dict for Dict
function adt2client(lang::Python, x)
    @match x begin
        ###################### Generic Compsite Types ######################
        ::JugsawADT.Object => begin
            if startswith(x.typename, "JugsawIR.JArray")
                "numpy.reshape($(x.fields[2].storage), $(x.fields[1]))"
            elseif startswith(x.typename, "JugsawIR.JDict")
                kvpairs = join(["$(adt2client(lang, k)):$(adt2client(lang, v))" for (k, v) in zip(x.fields[1], x.fields[2])], ", ")
                "{$kvpairs}"
            elseif startswith(x.typename, "JugsawIR.JEnum")
                repr(x.value)
            else
                vals = [adt2client(lang, field) for (field, fn) in zip(t.fields, fieldnames(T)) if isdefined(demo, fn)]
                "(" * join(vals, ", ") * ")"
            end
        end
        ::JugsawADT.Vector => "[" * join([adt2client(lang, v) for v in x], ", ") * "]"
        ##################### Primitive types ###################
        _ => repr(x)
    end
end

function _generate_code(::Javascript, endpoint::String, appname::Symbol, fcall::JugsawADT, typetable::TypeTable)
    fname, fargs, fkwargs = fcall.fields
    args = join([adt2client(Javascript(), arg) for arg in fargs], ", ")
    kwargs = join([adt2client(Javascript(), arg) for arg in fkwargs], ", ")
    code = """<!-- include the jugsaw library -->
<script type="text/javascript" src="https://cdn.jsdelivr.net/gh/Jugsaw/Jugsaw/src/js/jugsawirparser.js"></script>

<!-- The function call -->
<script>
// call
call("$endpoint", "unspecified", "$appname", "$fname",
        {"type":"$type_args", "fields":[$args]},
        {"type":"$type_kwargs", "fields":[$kwargs]}).then(
            if (resp.status != 200){
                // call error
                console.log(resp.json().error);
            } else {
                // an object id is returned
                const res = fetch_result("$endpoint", obj.json().job_id).then(resp => {
                if (resp.status == 200){
                    // fetch result with the object id
                    resp.text().then(ir=>{
                        // the result is returned as a Jugsaw object.
                        const result = ir2adt(ir);
                        console.log(result);
                    })
                } else {
                    console.log(resp.json().error);
                }
            })

         }
     }
</script>
"""
    return code
end
function adt2client(lang::Javascript, x)
    @match x begin
        ###################### Generic Compsite Types ######################
        ::JugsawADT.Object => begin
            if startswith(x.typename, "JugsawIR.JArray")
                "numpy.reshape($(x.fields[2].storage), $(x.fields[1]))"
            elseif startswith(x.typename, "JugsawIR.JDict")
                kvpairs = join(["$(adt2client(lang, k)):$(adt2client(lang, v))" for (k, v) in zip(x.fields[1], x.fields[2])], ", ")
                "{$kvpairs}"
            elseif startswith(x.typename, "JugsawIR.JEnum")
                repr(x.value)
            else
                vals = [adt2client(lang, field) for (field, fn) in zip(t.fields, fieldnames(T)) if isdefined(demo, fn)]
                "(" * join(vals, ", ") * ")"
            end
        end
        ::JugsawADT.Vector => "[" * join([adt2client(lang, v) for v in x], ", ") * "]"
        ##################### Primitive types ###################
        _ => repr(x)
    end
end

function adt2client(lang::Javascript, x)
    @match x begin
        ###################### Generic Compsite Types ######################
        ::JugsawADT.Object => begin
            if startswith(x.typename, "JugsawIR.JEnum")
                repr(x.value)
            else
                vals = [adt2client(lang, field) for (field, fn) in zip(t.fields, fieldnames(T)) if isdefined(demo, fn)]
                """{"fields" : [$(join(vals, ", "))]}"""
            end
        end
        ::JugsawADT.Vector => "[" * join([adt2client(lang, v) for v in x], ", ") * "]"
        ##################### Primitive types ###################
        _ => repr(x)
    end
end