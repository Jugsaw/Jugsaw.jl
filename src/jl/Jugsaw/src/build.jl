export build

using TOML

function build(app_dir)
    docker_file = joinpath(app_dir, "Dockerfile")
    config = TOML.parsefile(joinpath(app_dir, "Project.toml"))
end