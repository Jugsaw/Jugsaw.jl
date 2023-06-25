module Template
# we copied some code from PkgTemplates
using TOML, LibGit2, Pkg
using UUIDs

# TODO: sanity check for the input symbol

function init(appname::Symbol; version::VersionNumber=v"1.0.0-DEV",
    authors::AbstractString=default_authors(),
    basedir::AbstractString=pwd(),
    juliaversion::VersionNumber=default_version(),
    dockerport::Int=8081)
    appdir = joinpath(basedir, String(appname))
    @info "Generated Jugsaw app `$appname` at folder: $appdir"
    mkpath(appdir)
    toml = project_config(; version, authors, appname, juliaversion)
    open(joinpath(appdir, "Project.toml"), "w") do f
        TOML.print(f, toml, sorted=true, by=key -> (project_key_order(key), key))
    end
    open(joinpath(appdir, "Dockerfile"), "w") do f
        write(f, docker_config(; juliaversion, dockerport))
    end
    open(joinpath(appdir, "README"), "w") do f
        println(f, "# $appname")
    end
    open(joinpath(appdir, "app.jl"), "w") do f
        println(f, app_demo(appname))
    end
    open(joinpath(appdir, "server.jl"), "w") do f
        println(f, server_demo())
    end
    Pkg.activate(appdir)
    Pkg.instantiate()
    @info("Success, please type `julia --project server.jl` to debug your application locally.
To upload your application to Jugsaw website, please check https://jugsaw.github.io/Jugsaw/dev/developer")
end

function project_config(; version::VersionNumber,
    authors::AbstractString=default_authors(),
    appname::Symbol,
    juliaversion::VersionNumber=default_version())
    return Dict(
        "jugsaw" => Dict(
            "name" => String(appname),
            "uuid" => string(uuid4()),
            "authors" => authors,
            "version" => string(version)
        ),
        "deps" => Dict("Jugsaw" => "506f6749-58fa-473a-ada6-eb0172fb6950"),
        "compat" => Dict("julia" => compat_version(juliaversion)),
    )
end

default_version() = VersionNumber(VERSION.major)

function default_authors()
    name = LibGit2.getconfig("user.name", "")
    isempty(name) && return "contributors"
    email = LibGit2.getconfig("user.email", "")
    authors = isempty(email) ? name : "$name <$email>"
    return "$authors and contributors"
end

function project_key_order(key::String)
    _project_key_order = ["name", "uuid", "keywords", "license", "desc", "deps", "compat"]
    return something(findfirst(x -> x == key, _project_key_order), length(_project_key_order) + 1)
end

"""
    compat_version(v::VersionNumber) -> String
Format a `VersionNumber` to exclude trailing zero components.
"""
function compat_version(v::VersionNumber)
    return if v.patch == 0 && v.minor == 0
        "$(v.major)"
    elseif v.patch == 0
        "$(v.major).$(v.minor)"
    else
        "$(v.major).$(v.minor).$(v.patch)"
    end
end

function docker_config(; juliaversion::VersionNumber, dockerport::Int=8081)
    """
    ARG JULIA_VERSION=$(juliaversion)
    FROM julia:\$JULIA_VERSION

    # FIXME: no need to develop Jugsaw once it is registered
    COPY . /app
    WORKDIR /app
    # The environment varialbe `JUGSAW_SERVER=DOCKER` turns the local mode off
    RUN JUGSAW_SERVER=DOCKER julia --project=. -e "using Pkg; Pkg.instantiate()"

    EXPOSE $dockerport
    ENTRYPOINT ["julia", "--project=.", "app.jl"]
    """
end

function app_demo(appname::Symbol)
    """
    # Please check Jugsaw documentation: TBD
    using Jugsaw

    "
        greet(x)

    This is the docstring, in which **markdown** grammar and math equations are supported

    ```math
    x^2
    ```
    "
    greet(x::String) = "Hello, \$(x)!"

    # create an application
    app = Jugsaw.AppSpecification(:$appname)

    @register app begin
        # register by demo
        greet("Jugsaw")
        # register by test case, here four functions `sin`, `cos`, `^`, `+` are registered.
        sin(0.5) ^ 2 + cos(0.5) ^ 2 ≈ 1.0
    end
    """
end

function server_demo()
    """
    import Jugsaw, Revise

    Revise.includet("app.jl")

    # reload the application on change
    Jugsaw.Server.serve(app; watched_files=["app.jl"])
    """
end
end