function start_server(app::AppSpecification, dapr::AbstractEventService; host::String="0.0.0.0", port::Int=8088, localurl::Bool=false)
    r = get_router(localurl ? LocalRoute() : RemoteRoute(), AppRuntime(app, dapr))
    server_task = @async try
        @info "✓ Server Started!"
        HTTP.serve(r, host, port)
    catch e
        e === :stop || rethrow()
    end
    errormonitor(server_task)
end

function stop_server(task)
    schedule(task, :stop, error=true)
    wait(task)
end

function liveserve(app::AppSpecification, dapr::AbstractEventService; watched_files, host::String="0.0.0.0",
        port::Int=8088, localurl::Bool=false, launch_browser::Bool=true)
    server_task = Ref(start_server(app, dapr; localurl, host, port))
    launch_browser && open_in_default_browser("http://$host:$port")
    Revise.entr(watched_files, [], postpone=true) do
        stop_server(server_task[])
        server_task[] = start_server(app, dapr; localurl, host, port)
    end
end

"""
    open_in_default_browser(url)

Open a URL in the ambient default browser.

Note: this was copied from `LiveServer.jl`, and the original copy is from `Pluto.jl`.
"""
function open_in_default_browser(url::AbstractString)::Bool
    @info "live"
    try
        if Sys.isapple()
            Base.run(`open $url`)
            true
        elseif Sys.iswindows() || detectwsl()
            Base.run(`cmd.exe /s /c start "" /b $url`)
            true
        elseif Sys.islinux()
            Base.run(`xdg-open $url`)
            true
        else
            false
        end
    catch ex
        @warn ex
        false
    end
end
function detectwsl()
    Sys.islinux() &&
    isfile("/proc/sys/kernel/osrelease") &&
    occursin(r"Microsoft|WSL"i, read("/proc/sys/kernel/osrelease", String))
end