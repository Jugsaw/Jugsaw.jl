#=
parent_path=$( cd "$(dirname "${BASH_SOURCE[0]}")" ; pwd -P )
JULIA_PROJECT=${parent_path} exec julia \
    --startup-file=no \
    --color=yes \
    --compile=min \
    --optimize=2 \
    -- "${BASH_SOURCE[0]}" "$@"
=#

using Pkg
if !isfile(joinpath(@__DIR__, "Manifest.toml"))
    Pkg.develop([Pkg.PackageSpec("../src/jl/JugsawIR"), Pkg.PackageSpec("../src/jl/Jugsaw")])
    Pkg.instantiate()
end

# write your Julia code
using LiveServer; servedocs(;skip_dirs=String[])
