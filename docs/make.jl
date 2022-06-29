using SimpleWorkflows
using Documenter

DocMeta.setdocmeta!(SimpleWorkflows, :DocTestSetup, :(using SimpleWorkflows); recursive=true)

makedocs(;
    modules=[SimpleWorkflows],
    authors="Reno <singularitti@outlook.com>",
    repo="https://github.com/MineralsCloud/SimpleWorkflows.jl/blob/{commit}{path}#{line}",
    sitename="SimpleWorkflows.jl",
    format=Documenter.HTML(;
        prettyurls=get(ENV, "CI", "false") == "true",
        canonical="https://MineralsCloud.github.io/SimpleWorkflows.jl",
        assets=String[],
    ),
    pages=[
        "Home" => "index.md",
        "Manual" => [
            "Installation guide" => "installation.md",
        ],
    ],
)

deploydocs(;
    repo="github.com/MineralsCloud/SimpleWorkflows.jl",
)
