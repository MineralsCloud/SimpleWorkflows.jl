#! format: off
using SimpleWorkflows
using Documenter

DocMeta.setdocmeta!(SimpleWorkflows, :DocTestSetup, :(using SimpleWorkflows); recursive=true)

makedocs(;
    modules=[SimpleWorkflows],
    authors="singularitti <singularitti@outlook.com>",
    repo="https://github.com/MineralsCloud/SimpleWorkflows.jl/blob/{commit}{path}#{line}",
    sitename="SimpleWorkflows.jl",
    format=Documenter.HTML(;
        prettyurls=get(ENV, "CI", "false") == "true",
        canonical="https://MineralsCloud.github.io/SimpleWorkflows.jl",
        edit_link="main",
        assets=String[],
    ),
    pages=[
        "Home" => "index.md",
        "Manual" => [
            "Installation guide" => "installation.md",
            "Portability" => "portability.md",
        ],
        "Public API" => "public.md",
        "Developer Docs" => [
            "Contributing" => "developers/contributing.md",
            "Style Guide" => "developers/style-guide.md",
            "Design Principles" => "developers/design-principles.md",
        ],
        "Troubleshooting" => "troubleshooting.md",
    ],
)

deploydocs(;
    repo="github.com/MineralsCloud/SimpleWorkflows.jl",
    devbranch="main",
)
