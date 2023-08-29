const GLOBAL_CONFIG = Dict{String, Any}(
    "host" => "http://0.0.0.0",
    "port" => 8088,
    "network-timeout" => 15.0,
    "query-interval" => 0.1,
    "jugsaw-server" => "LOCAL"
)
function get_endpoint()
    return """$(GLOBAL_CONFIG["host"]):$(GLOBAL_CONFIG["port"])"""
end

"""
$TYPEDSIGNATURES

Load configurations from the input `.toml` file.
"""
function load_config_file!(configfile::String)
    config = open(configfile) do f
        TOML.parse(f)
    end
    return update_config!(GLOBAL_CONFIG, config)
end
function load_config_env!()
    return update_config!(GLOBAL_CONFIG, ENV)
end
function update_config!(a::Dict, b)
    for (k, v) in a
        !haskey(b, k) && continue
        if v isa Dict
            update_config!(v, b[k])
        else
            a[k] = b[k]
        end
    end
    return a
end

# update configurations from the environmental variables
load_config_env!()

# How to configure Jugsaw app?
# 1. through configuration files