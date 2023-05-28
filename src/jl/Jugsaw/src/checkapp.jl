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
    context = Client.ClientContext()
    niters = 20
    for i=1:niters
        @info "$i/$niters"
        try
            @assert Client.healthz(context).status == "OK"
            app = Client.request_app(context, Symbol(basename(dir)))
            return Client.test_demo(app)
        catch e
            Base.showerror(stdout, e)
            sleep(3)
        end
    end

    # turn down service
    schedule(t, InterruptException(), error=true)
    return false
end