module Template
# we copied some code from PkgTemplates
using TOML, LibGit2
using UUIDs

function init(; version::VersionNumber=v"1.0.0-DEV",
        authors::AbstractString = default_authors(),
        basedir::AbstractString,
        appname::Symbol,
        juliaversion::VersionNumber=default_version(),
        dockerport::Int=8081)
    appdir = joinpath(basedir, String(appname))
    mkpath(appdir)
    toml = project_config(; version, authors, appname, juliaversion)
    open(joinpath(appdir, "Project.toml"), "w") do f
        TOML.print(f, toml, sorted = true, by = key -> (project_key_order(key), key))
    end
    open(joinpath(appdir, "Dockerfile"), "w") do f
        write(f, docker_config(; juliaversion, appname, dockerport))
    end
    open(joinpath(appdir, "README"), "w") do f
        println(f, "# $appname")
    end
end

function project_config(; version::VersionNumber,
        authors::AbstractString = default_authors(),
        appname::Symbol,
        juliaversion::VersionNumber=default_version())
    return Dict(
        "name" => String(appname),
        "uuid" => string(uuid4()),
        "authors" => authors,
        "version" => string(version),
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

function docker_config(; juliaversion::VersionNumber,
        appname::Symbol, dockerport::Int=8081)
    return """
ARG JULIA_VERSION=$(juliaversion)
FROM julia:\$JULIA_VERSION

# FIXME: no need to develop Jugsaw once it is registered
COPY . /$appname
WORKDIR /$appname
RUN julia --project=. -e "using Pkg; Pkg.instantiate()"

EXPOSE $dockerport
ENTRYPOINT ["julia", "--project=.", "app.jl"]
"""
end

end