using TOML

struct Config
    app::String
end

function load_config(path::String)
    if isdir(path)
        load_config(joinpath(path, "Project.toml"))
    else
        project = TOML.parsefile(path)
        Config(project["jugsaw"]["name"])
    end
end