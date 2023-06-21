abstract type AbstractLang end
struct Julia <: AbstractLang end
struct Python <: AbstractLang end
struct Javascript <: AbstractLang end

"""
$TYPEDSIGNATURES

Generate code for target language.

### Arguments
* `lang` can be a string or an [`AbstractLang`](@ref) instance that specifies the target language.
Please use `subtypes(AbstractLang)` for supported client languages.
* `endpoint` is the url for service provider, e.g. it can be [https://www.jugsaw.co](https://www.jugsaw.co).
* `appname` is the application name.
* `fcall` is a [`JugsawADT`](@ref) that specifies the function call.
* `idx` is the index of method instance.
* `typetable` is a [`TypeTable`](@ref) instance with the type definitions.
"""
function generate_code(lang::String, endpoint, appname, fcall::JugsawADT, idx::Int, typetable::JugsawADT)
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
    return _generate_code(pl, endpoint, appname, fcall, idx, tt)
end

aslist(x::JugsawADT) = x.fields[2]

# converting IR to different languages
function _generate_code(::Julia, endpoint::String, appname::Symbol, fcall::JugsawADT, idx::Int, typetable::TypeTable)
    fname, fargs, fkwargs = fcall.fields
    args = join([adt2client(Julia(), arg) for arg in fargs.fields],", ")
    kws = typetable.defs[fkwargs.typename].fieldnames
    kwargs = join(["$key = $(adt2client(Julia(), arg))" for (key, arg) in zip(kws, fkwargs.fields)],", ")
    code = """using Jugsaw.Client
app = request_app(ClientContext(; endpoint=$(repr(endpoint)), :$(appname)))
app.$fname[$idx]($args; $kwargs)"""
    return code
end
function adt2client(lang::Julia, x)
    @match x begin
        ###################### Generic Compsite Types ######################
        ::JugsawADT => @match x.head begin
            :Object => if startswith(x.typename, "JugsawIR.JArray")
                content = join([adt2client(lang, elem) for elem in x.fields[2].storage], ", ")
                size = join([string(x) for x in x.fields[1].storage], ", ")
                length(size) > 1 ? "reshape([$content], $size)" : "[$content]"
            elseif startswith(x.typename, "JugsawIR.JDict")
                kvpairs = join(["$(adt2client(lang, k)) => $(adt2client(lang, v))" for (k, v) in zip(aslist(x.fields[1]).storage, aslist(x.fields[2]).storage)], ", ")
                "Dict($kvpairs)"
            elseif startswith(x.typename, "JugsawIR.JEnum")
                repr(x.fields[2])
            else
                vals = [adt2client(lang, field) for field in x.fields]
                "(" * join(vals, ", ") * ")"
            end
            :Vector => "[" * join([adt2client(lang, v) for v in x], ", ") * "]"
        end
        ##################### Primitive types ###################
        _ => repr(x)
    end
end

function _generate_code(::Python, endpoint::String, appname::Symbol, fcall::JugsawADT, idx::Int, typetable::TypeTable)
    fname, fargs, fkwargs = fcall.fields
    args = join([adt2client(Python(), arg) for arg in fargs.fields],", ")
    kws = typetable.defs[fkwargs.typename].fieldnames
    kwargs = join(["$key = $(adt2client(Python(), arg))" for (key, arg) in zip(kws, fkwargs.fields)],", ")
    code = """import jugsaw, numpy
app = jugsaw.request_app(jugsaw.ClientContext(; endpoint=$(repr(endpoint))), $(repr(string(appname))))
app.$fname[$(idx-1)]($args, $kwargs)"""
    return code
end
# We use tuple for objects
# numpy array for Array
# dict for Dict
function adt2client(lang::Python, x)
    @match x begin
        ###################### Generic Compsite Types ######################
        ::JugsawADT => @match x.head begin
            :Object => if startswith(x.typename, "JugsawIR.JArray")
                storage = join([adt2client(lang, v) for v in x.fields[2].storage], ", ")
                size = (x.fields[1].storage...,)
                length(size) == 1 ? "[$storage]" : "numpy.reshape([$storage], $size, order='F')"
            elseif startswith(x.typename, "JugsawIR.JDict")
                kvpairs = join(["$(adt2client(lang, k)):$(adt2client(lang, v))" for (k, v) in zip(aslist(x.fields[1]).storage, aslist(x.fields[2]).storage)], ", ")
                "{$kvpairs}"
            elseif startswith(x.typename, "JugsawIR.JEnum")
                repr(x.fields[2])
            else
                vals = [adt2client(lang, field) for field in x.fields]
                "(" * join(vals, ", ") * ")"
            end
            :Vector => "[" * join([adt2client(lang, v) for v in x], ", ") * "]"
        end
        ##################### Primitive types ###################
        ::Nothing => "None"
        ::Bool => x ? "True" : "False"
        _ => repr(x)
    end
end

function _generate_code(::Javascript, endpoint::String, appname::Symbol, fcall::JugsawADT, idx::Int, typetable::TypeTable)
    fname, fargs, fkwargs = fcall.fields
    args = adt2client(Javascript(), fargs)
    kws = typetable.defs[fkwargs.typename].fieldnames
    kwargs = adt2client(Javascript(), fkwargs)
    code = """<!-- include the jugsaw library -->
<script type="text/javascript" src="https://cdn.jsdelivr.net/gh/Jugsaw/Jugsaw/src/js/jugsawirparser.js"></script>

<!-- The function call -->
<script>
// call
const context = ClientContext(; endpoint="$endpoint")
const app = request_app(context, "$appname")
// keyword arguments are: $kws
const result = app.call("$fname", $idx, $args, $kwargs)
console.log(result.fetch())
</script>"""
    return code
end
function adt2client(lang::Javascript, x)
    @match x begin
        ###################### Generic Compsite Types ######################
        ::JugsawADT => @match x.head begin
            :Object => if startswith(x.typename, "JugsawIR.JEnum")
                repr(x.fields[2])
            else
                vals = [adt2client(lang, field) for field in x.fields]
                """[$(join(vals, ", "))]"""
            end
            :Vector => "[" * join([adt2client(lang, v) for v in x.storage], ", ") * "]"
        end
        ##################### Primitive types ###################
        ::Nothing => "null"
        _ => repr(x)
    end
end