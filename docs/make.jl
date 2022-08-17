using SimpleWorkflows
using Documenter

DocMeta.setdocmeta!(
    SimpleWorkflows,
    :DocTestSetup,
    :(using SimpleWorkflows,
        SimpleWorkflows.Thunks, SimpleWorkflows.Jobs, SimpleWorkflows.Workflows);
    recursive=true,
)

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
            "Contributing" => "contributing.md",
        ],
        "Library" => "public.md",
        "Troubleshooting" => "troubleshooting.md",
    ],
)

deploydocs(;
    repo="github.com/MineralsCloud/SimpleWorkflows.jl",
)
