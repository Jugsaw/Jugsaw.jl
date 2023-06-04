############# Inspired by LiveServer.jl
"""
    WatchedFile

Struct for a file being watched containing the path to the file as well as the time of last
modification.
"""
mutable struct WatchedFile{T<:AbstractString}
    const path::T
    mtime::Float64
end

"""
    WatchedFile(f_path)

Construct a new `WatchedFile` object around a file `f_path`.
"""
WatchedFile(f_path::AbstractString) = WatchedFile(f_path, mtime(f_path))

"""
    set_unchanged!(wf::WatchedFile)

Set the current state of a `WatchedFile` as unchanged"
"""
set_unchanged!(wf::WatchedFile) = (wf.mtime = mtime(wf.path))

mutable struct FileWatcher
    const callback                    # callback function triggered upon file change
    # task::Union{Nothing,Task}         # asynchronous file-watching task
    const sleeptime::Float64                # sleep-time before checking for file changes
    const watchedfiles::Vector{WatchedFile} # list of files being watched
    status::Symbol                    # set to :interrupted as appropriate (caught by server)
end
FileWatcher(callback; sleeptime::Float64=0.1) =
    FileWatcher(callback, sleeptime, Vector{WatchedFile}(), :runnable)

"""
    has_changed(wf::WatchedFile)

Check if a `WatchedFile` has changed. Returns -1 if the file does not exist, 0 if it does exist but
has not changed, and 1 if it has changed.
"""
function has_changed(wf::WatchedFile)
    !isfile(wf.path) && return -1
    return Int(mtime(wf.path) > wf.mtime)
end

"""
    file_watcher_task!(w::FileWatcher)

Helper function that's spawned as an asynchronous task and checks for file changes. This task
is normally terminated upon an `InterruptException` and shows a warning in the presence of
any other exception.
"""
function file_watcher_task!(fw::FileWatcher)
    try
        while true
            sleep(fw.sleeptime)

            # only check files if there's a callback to call upon changes
            fw.callback === nothing && continue

            # keep track of any file that may have been deleted
            deleted_files = Vector{Int}()
            for (i, wf) ∈ enumerate(fw.watchedfiles)
                state = has_changed(wf)
                if state == 0
                    continue
                elseif state == 1
                    # the file has changed, set it unchanged and trigger callback
                    set_unchanged!(wf)
                    fw.callback(wf.path)
                elseif state == -1
                    # the file does not exist, eventually delete it from list of watched files
                    push!(deleted_files, i)
                    @debug "[FileWatcher]: file '$(wf.path)' does not " *
                            "exist (anymore); removing it from list of " *
                            " watched files."
                end
            end
            # remove deleted files from list of watched files
            deleteat!(fw.watchedfiles, deleted_files)
        end
    catch err
        fw.status = :interrupted
        # an InterruptException is the normal way for this task to end
        if !isa(err, InterruptException)
            @error "fw error" exception=(err, catch_backtrace())
        end
        return nothing
    end
end

function watch_file(fw::FileWatcher)
    task = @async file_watcher_task!(fw)
    # wait until task runs to ensure reliable start (e.g. if `stop` called right afterwards)
    while task.state != :runnable
        sleep(0.01)
    end
end