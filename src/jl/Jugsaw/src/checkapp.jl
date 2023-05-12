function checkapp(dir::String)
    jugsawdir = pkgdir(Jugsaw)
    jugsawirdir = pkgdir(JugsawIR)
    # start service
    mod = Core.eval(@__MODULE__, :(module Workspace
        using Pkg
        Pkg.activate($dir)
        Pkg.develop([Pkg.PackageSpec(path=$jugsawdir), Pkg.PackageSpec(; path=$jugsawirdir)])
        Pkg.instantiate()
    end))
    t = @async Core.eval(Workspace, :(include(joinpath($dir, "app.jl"))))

     # run tasks
    remote = Client.RemoteHandler()  # on the default port
    nsuccess = 0
    total = 0
    niters = 20
    for i=1:niters
        @info "$i/$niters"
        try
            @assert Client.healthz(remote).status == "OK"
            app = Client.request_app(remote, Symbol(basename(dir)))
            for (fname, demo) in app[:method_demos]
                total += 1
                if Client.test_demo(remote, app, fname)
                    nsuccess += 1
                end
            end
            break
        catch e
            Base.showerror(stdout, e)
            sleep(3)
        end
    end

    # turn down service
    schedule(t, InterruptException(), error=true)
    @info "$nsuccess/$total demos are healthy."
    return nsuccess, total
end