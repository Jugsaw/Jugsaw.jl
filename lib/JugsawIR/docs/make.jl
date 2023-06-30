using JugsawIR
using Documenter

DocMeta.setdocmeta!(JugsawIR, :DocTestSetup, :(using JugsawIR); recursive=true)

makedocs(;
    modules=[JugsawIR],
    authors="GiggleLiu <cacate0129@gmail.com> and contributors",
    repo="https://github.com/GiggleLiu/JugsawIR.jl/blob/{commit}{path}#{line}",
    sitename="JugsawIR.jl",
    format=Documenter.HTML(;
        prettyurls=get(ENV, "CI", "false") == "true",
        canonical="https://GiggleLiu.github.io/JugsawIR.jl",
        edit_link="main",
        assets=String[],
    ),
    pages=[
        "Home" => "index.md",
    ],
)

deploydocs(;
    repo="github.com/GiggleLiu/JugsawIR.jl",
    devbranch="main",
)
