module Template
# we copied some code from PkgTemplates
using TOML, LibGit2, Pkg
using UUIDs

# TODO: sanity check for the input symbol

function init(appname::Symbol; version::VersionNumber=v"1.0.0-DEV",
        authors::AbstractString=default_authors(),
        basedir::AbstractString=pwd(),
        juliaversion::VersionNumber=default_version(),
        dockerport::Int=7860,
        instantiate::Bool=false
    )
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
    if instantiate
        Pkg.activate(appdir)
        Pkg.instantiate()
    end
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

default_version() = VersionNumber(VERSION)

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

function docker_config(; juliaversion::VersionNumber=default_version(), hostname::String="0.0.0.0", dockerport::Int=7860)
"""
ARG JULIA_VERSION=$juliaversion
# The environment varialbe `JUGSAW_SERVER=DOCKER` turns the local mode off
ARG JUGSAW_SERVER=DOCKER
FROM julia:\$JULIA_VERSION

# FIXME: no need to develop Jugsaw once it is registered
COPY . /app
WORKDIR /app
# The `JULIA_DEPOT_PATH` is the path to store Julia packages
ARG JULIA_DEPOT_PATH=/app
RUN julia --project=/app -e "using Pkg; Pkg.instantiate()"
# Change Julia package permission to 777, because Huggingface entry point is not executed by root!!
RUN chmod -R 777 /app

EXPOSE $dockerport
# To affect entrypoint, set `ENV` rather than `ARG`
ENV JULIA_DEPOT_PATH=\$JULIA_DEPOT_PATH
ENTRYPOINT ["julia", "--project=/app", "-e", "import Jugsaw; include(\\\"app.jl\\\"); Jugsaw.Server.serve(Jugsaw.APP, host=\"$hostname\", port=$dockerport);"]
"""
end

function app_demo(appname::Symbol)
    """
    # Jugsaw Developer Guide: TBD
    using Jugsaw

    \"\"\"
        greet(x)

    This is the docstring, in which **markdown** grammar and math equations are supported

    ```math
    x^2
    ```
    \"\"\"
    greet(x::String) = "Hello, \$(x)!"

    # create an application
    @register $appname begin
        # register by demo
        greet("Jugsaw")
    end
    """
end

function server_demo()
    """
    import Jugsaw, Revise

    Revise.includet("app.jl")
    @info "Running application: " Jugsaw.APP

    # reload the application on change
    Jugsaw.Server.serve(Jugsaw.APP; watched_files=["app.jl"])
    """
end
end
