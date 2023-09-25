"""
$TYPEDEF

This error was thrown when a demo matching the target type signature is not found.

### Fields
$TYPEDFIELDS
"""
struct NoDemoException <: Exception
    func_sig
    methods
end
function Base.showerror(io::IO, e::NoDemoException, trace)
    print(io, "method does not exist, got: $(e.func_sig), available functions are: $(e.methods)")
end

struct TimedOutException <: Exception
    job_id::String
    timelimit::Float64
end
function Base.showerror(io::IO, e::TimedOutException, trace)
    print(io, "Job $(e.job_id) does not finish in time limit: $(e.timelimit) (seconds)")
end

struct BadSyntax <: Exception
    adt
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

# cache the error to be thrown (used inside the task)
struct CachedError
    exception::Exception
    msg::String
end