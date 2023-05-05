using Jugsaw
using JugsawIR
using Documenter, DocumenterMarkdown

formats = length(ARGS) >= 1 ? ARGS[1:end] : ["HTML"]
allowed_formats = ["HTML", "Markdown"]
any(∉(allowed_formats), formats) && error("documentation format error, expected $allowed_formats, but got: $formats")

for fmt in formats
    format, build = if fmt == "HTML"
        Documenter.HTML(;
            prettyurls=get(ENV, "CI", "false") == "true",
            canonical="https://Jugsaw.github.io/Jugsaw.jl",
            edit_link="main",
            assets=String[],
        ), "build"
    else
        DocumenterMarkdown.Markdown(), "build-markdown"
    end

    @info "generating documents of format: $format"

    makedocs(;
        build=joinpath(@__DIR__, build),
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
end

deploydocs(;
    repo="github.com/Jugsaw/Jugsaw.jl",
    devbranch="main",
)