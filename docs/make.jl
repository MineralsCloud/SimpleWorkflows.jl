using SimpleWorkflow
using Documenter

makedocs(;
    modules=[SimpleWorkflow],
    authors="Qi Zhang <singularitti@outlook.com>",
    repo="https://github.com/MineralsCloud/SimpleWorkflow.jl/blob/{commit}{path}#L{line}",
    sitename="SimpleWorkflow.jl",
    format=Documenter.HTML(;
        prettyurls=get(ENV, "CI", "false") == "true",
        canonical="https://MineralsCloud.github.io/SimpleWorkflow.jl",
        assets=String[],
    ),
    pages=[
        "Home" => "index.md",
    ],
)

deploydocs(;
    repo="github.com/MineralsCloud/SimpleWorkflow.jl",
)
