abstract type AbstractLang end
struct Julia <: AbstractLang end
struct Python <: AbstractLang end
struct Javascript <: AbstractLang end
struct CLI <: AbstractLang end

"""
$TYPEDSIGNATURES

Generate code for target language.

### Arguments
* `lang` can be a string or an [`AbstractLang`](@ref) instance that specifies the target language.
Please use `subtypes(AbstractLang)` for supported client languages.
* `endpoint` is the url for service provider, e.g. it can be [https://www.jugsaw.co](https://www.jugsaw.co).
* `appname` is the application name.
* `fcall` is a object that specifies the function call.
* `typetable` is a [`TypeTable`](@ref) instance with the type definitions.
"""
function generate_code(lang::String, endpoint, appname, fname, fcall, typetable)
    @assert fcall.head == :call
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
    elseif lang == "CLI"
        CLI()
    else
        return error("Client langauge not defined, got: $lang")
    end
    return _generate_code(pl, endpoint, appname, Symbol(fname), fcall, tt)
end

# converting IR to different languages
function _generate_code(::Julia, endpoint::String, appname::Symbol, fname::Symbol, fcall, typetable::TypeTable)
    _, fargs, fkwargs = unpack_call(fcall)
    args = join([adt2client(Julia(), arg) for arg in unpack_fields(fargs)],", ")
    kws = typetable.defs[unpack_typename(fkwargs)].fieldnames
    kwargs = join(["$key = $(adt2client(Julia(), arg))" for (key, arg) in zip(kws, unpack_fields(fkwargs))],", ")
    code = """using Jugsaw.Client
app = request_app(ClientContext(; endpoint=$(repr(endpoint))), :$(appname))
lazyreturn = app.$fname($args; $kwargs)
result = lazyreturn()  # fetch result"""
    return code
end
function adt2client(lang::Julia, x)
    @match x begin
        ###################### Generic Compsite Types ######################
        ::JugsawExpr => @match x.head begin
            :object => begin
                typename, fields = unpack_object(x)
                if startswith(typename, "JugsawIR.JArray")
                    content = join([adt2client(lang, elem) for elem in unpack_list(fields[2])], ", ")
                    size = join([string(x) for x in unpack_list(fields[1])], ", ")
                    length(size) > 1 ? "reshape([$content], $size)" : "[$content]"
                elseif startswith(typename, "JugsawIR.JDict")
                    kvpairs = join([((k, v) = unpack_fields(pair); "$(adt2client(lang, k)) => $(adt2client(lang, v))") for pair in unpack_list(fields[1])], ", ")
                    "Dict($kvpairs)"
                else
                    vals = [adt2client(lang, field) for field in fields]
                    "(" * join(vals, ", ") * ")"
                end
            end
            :list => "[" * join([adt2client(lang, v) for v in unpack_list(x)], ", ") * "]"
        end
        ##################### Primitive types ###################
        _ => repr(x)
    end
end

function _generate_code(::Python, endpoint::String, appname::Symbol, fname::Symbol, fcall::JugsawExpr, typetable::TypeTable)
    _, fargs, fkwargs = unpack_call(fcall)
    args = join([adt2client(Python(), arg) for arg in unpack_fields(fargs)],", ")
    kws = typetable.defs[unpack_typename(fkwargs)].fieldnames
    kwargs = join(["$key = $(adt2client(Python(), arg))" for (key, arg) in zip(kws, unpack_fields(fkwargs))],", ")
    code = """import jugsaw, numpy
app = jugsaw.request_app(jugsaw.ClientContext(endpoint=$(repr(endpoint))), $(repr(string(appname))))
lazyreturn = app.$fname($(join(filter!(!isempty, [args, kwargs]), ", ")))
result = lazyreturn()   # fetch result"""
    return code
end
# We use tuple for objects
# numpy array for Array
# dict for Dict
function adt2client(lang::Python, x)
    @match x begin
        ###################### Generic Compsite Types ######################
        ::JugsawExpr => @match x.head begin
            :object => begin
                typename, fields = unpack_object(x)
                if startswith(typename, "JugsawIR.JArray")
                    size = (unpack_list(fields[1])...,)
                    storage = join([adt2client(lang, v) for v in unpack_list(fields[2])], ", ")
                    length(size) == 1 ? "[$storage]" : "numpy.reshape([$storage], $size, order='F')"
                elseif startswith(typename, "JugsawIR.JDict")
                    kvpairs = join([((k, v) = unpack_fields(pair); "$(adt2client(lang, k)):$(adt2client(lang, v))") for pair in unpack_list(fields[1])], ", ")
                    "{$kvpairs}"
                else
                    vals = [adt2client(lang, field) for field in unpack_fields(x)]
                    "(" * join(vals, ", ") * ")"
                end
            end
            :list => "[" * join([adt2client(lang, v) for v in unpack_list(x)], ", ") * "]"
        end
        ##################### Primitive types ###################
        ::Nothing => "None"
        ::Symbol => repr(String(x))
        ::Bool => x ? "True" : "False"
        _ => repr(x)
    end
end

function _generate_code(::Javascript, endpoint::String, appname::Symbol, fname::Symbol, fcall::JugsawExpr, typetable::TypeTable)
    _, fargs, fkwargs = unpack_call(fcall)
    args = adt2client(Javascript(), fargs)
    kws = typetable.defs[unpack_typename(fkwargs)].fieldnames
    kwargs = adt2client(Javascript(), fkwargs)
    code = """<!-- include the jugsaw library -->
<script type="text/javascript" src="https://cdn.jsdelivr.net/gh/Jugsaw/Jugsaw/src/js/jugsawirparser.js"></script>

<!-- The function call -->
<script>
// call
const context = new ClientContext({endpoint:"$endpoint"})
const app_promise = request_app(context, "$appname")
// keyword arguments are: $kws
app_promise.then(app=>app.call("$fname", $args, $kwargs)).then(console.log)
</script>"""
    return code
end
function adt2client(lang::Javascript, x)
    @match x begin
        ###################### Generic Compsite Types ######################
        ::JugsawExpr => @match x.head begin
            :object => begin
                typename, fields = unpack_object(x)
                vals = [adt2client(lang, field) for field in fields]
                """[$(join(vals, ", "))]"""
            end
            :list => "[" * join([adt2client(lang, v) for v in unpack_list(x)], ", ") * "]"
        end
        ##################### Primitive types ###################
        ::Nothing => "null"
        _ => repr(x)
    end
end

function adt2client(lang::CLI, x)
    @match x begin
        ###################### Generic Compsite Types ######################
        ::JugsawExpr => @match x.head begin
            :object => begin
                typename, fields = unpack_object(x)
                vals = [adt2client(lang, field) for field in unpack_fields(x)]
                "[" * join(vals, ", ") * "]"
            end
            :list => "[" * join([adt2client(lang, v) for v in unpack_list(x)], ", ") * "]"
        end
        ##################### Primitive types ###################
        ::Nothing => "null"
        ::Symbol => repr(String(x))
        ::Bool => x ? "true" : "false"
        ::JugsawIR.DirectlyRepresentableTypes => repr(x)
    end
end

function _generate_code(::CLI, endpoint::String, appname::Symbol, fname::Symbol, fcall::JugsawExpr, typetable::TypeTable)
    _, fargs, fkwargs = unpack_call(fcall)
    args = join([adt2client(CLI(), arg) for arg in unpack_fields(fargs)]," ")
    kws = typetable.defs[unpack_typename(fkwargs)].fieldnames
    kwargs = join(["$key=$(adt2client(CLI(), arg))" for (key, arg) in zip(kws, unpack_fields(fkwargs))]," ")
    code = """$endpoint $appname.$fname $args $kwargs"""
    return code
end