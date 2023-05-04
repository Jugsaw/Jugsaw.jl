using Jugsaw
using JugsawIR
using Documenter, DocumenterMarkdown

_format = length(ARGS) >= 1 ? ARGS[1] : "HTML"
format = if _format == "HTML"
    Documenter.HTML(;
        prettyurls=get(ENV, "CI", "false") == "true",
        canonical="https://Jugsaw.github.io/Jugsaw.jl",
        edit_link="main",
        assets=String[],
    )
elseif _format == "Markdown"
    DocumenterMarkdown.Markdown()
else
    error("documentation format error, got: $_format")
end

@info "generating documents of format: $format"

makedocs(;
    modules=[Jugsaw, JugsawIR],
    authors="Jugsaw Computing Inc.",
    repo="https://github.com/Jugsaw/Jugsaw.jl/blob/{commit}{path}#{line}",
    sitename = "Documentation | Jugsaw",
    format = format,
    pages=[
        "Home" => "index.md",
        "Get Started" => "get-started.md",
        "Clients" => ["client.md"],
        "Jugsaw Developer" => ["man/Jugsaw.md", "man/JugsawIR.md", "design.md"],
    ],
)

deploydocs(;
    repo="github.com/Jugsaw/Jugsaw.jl",
    devbranch="main",
)