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
            "Installation Guide" => "man/installation.md",
            "Portability" => "man/portability.md",
            "Troubleshooting" => "man/troubleshooting.md",
        ],
        "Reference" => Any[
            "Public API" => "lib/public.md",
            "Internals" => map(
                s -> "lib/internals/$(s)",
                sort(readdir(joinpath(@__DIR__, "src/lib/internals")))
            ),
        ],
        "Developer Docs" => [
            "Contributing" => "developers/contributing.md",
            "Style Guide" => "developers/style-guide.md",
            "Design Principles" => "developers/design-principles.md",
        ],
    ],
)

deploydocs(;
    repo="github.com/MineralsCloud/SimpleWorkflows.jl",
    devbranch="main",
)
