struct NoDemoException <: Exception
    func_sig
    methods
end
function Base.showerror(io::IO, e::NoDemoException, trace)
    print(io, "method does not exist, got: $(e.func_sig), available functions are: $(e.methods)")
end
struct BadSyntax <: Exception
    adt::JugsawADT
end
function Base.showerror(io::IO, e::BadSyntax, trace)
    buffer = IOBuffer()
    print(buffer, e.adt)
    s = String(take!(buffer))
    print(io, "Syntax error, got: $s")
end

function _error_msg(e)
    io = IOBuffer()
    showerror(io, e, catch_backtrace())
    return String(take!(io))
end

function _error_response(e::Exception)
    HTTP.Response(400, ["Content-Type" => "application/json"], JSON3.write((; error=_error_msg(e))))
end

# cache the error to be thrown (used inside the task)
struct CachedError
    exception::Exception
    msg::String
end