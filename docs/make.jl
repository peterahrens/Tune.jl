using Tune
using Documenter

makedocs(;
    modules=[Tune],
    authors="Peter Ahrens",
    repo="https://github.com/peterahrens/Tune.jl/blob/{commit}{path}#L{line}",
    sitename="Tune.jl",
    format=Documenter.HTML(;
        prettyurls=get(ENV, "CI", "false") == "true",
        canonical="https://peterahrens.github.io/Tune.jl",
        assets=String[],
    ),
    pages=[
        "Home" => "index.md",
    ],
)

deploydocs(;
    repo="github.com/peterahrens/Tune.jl",
)
