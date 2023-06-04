function start_server(app::AppSpecification, dapr::AbstractEventService; host::String="0.0.0.0", port::Int=8088, localmode::Bool=true)
    r = get_router(localmode ? LocalRoute() : RemoteRoute(), AppRuntime(app, dapr))
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