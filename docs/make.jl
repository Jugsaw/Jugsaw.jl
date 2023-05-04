using Jugsaw
using JugsawIR
using Documenter

makedocs(;
    modules=[Jugsaw, JugsawIR],
    authors="Jugsaw Computing Inc.",
    repo="https://github.com/Jugsaw/Jugsaw.jl/blob/{commit}{path}#{line}",
    sitename = "Documentation | Jugsaw",
    format=Documenter.HTML(;
        prettyurls=get(ENV, "CI", "false") == "true",
        canonical="https://Jugsaw.github.io/Jugsaw.jl",
        edit_link="main",
        assets=String[],
    ),
    pages=[
        "Home" => "index.md",
        "Get Started" => "get-started.md",
        "Clients" => ["client.md"],
        "Jugsaw Developer" => ["man/Jugsaw.md", "man/JugsawIR.md", "design.md"],
    ],
)

DocumenterTools.generate(path=@__DIR__; name = nothing, format = :markdown)
deploydocs(;
    repo="github.com/Jugsaw/Jugsaw.jl",
    devbranch="main",
)