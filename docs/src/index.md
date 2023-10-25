# SimpleWorkflows

Documentation for [SimpleWorkflows](https://github.com/MineralsCloud/SimpleWorkflows.jl).

See the [Index](@ref main-index) for the complete list of documented functions
and types.

The code, which is [hosted on GitHub](https://github.com/MineralsCloud/SimpleWorkflows.jl), is tested
using various continuous integration services for its validity.

This repository is created and maintained by
[@singularitti](https://github.com/singularitti), and contributions are highly welcome.

## Package features

Build workflows from jobs. Run, monitor, and get results from them.
This package takes inspiration from packages like
[JobSchedulers](https://github.com/cihga39871/JobSchedulers.jl) and
[Dispatcher](https://github.com/invenia/Dispatcher.jl) (unmaintained).

Please [cite this package](https://doi.org/10.1016/j.cpc.2022.108515) as:

Q. Zhang, C. Gu, J. Zhuang et al., `express`: extensible, high-level workflows for swifter *ab initio* materials modeling, *Computer Physics Communications*, 108515, doi: https://doi.org/10.1016/j.cpc.2022.108515.

The BibTeX format is:

```bibtex
@article{ZHANG2022108515,
  title    = {express: extensible, high-level workflows for swifter ab initio materials modeling},
  journal  = {Computer Physics Communications},
  pages    = {108515},
  year     = {2022},
  issn     = {0010-4655},
  doi      = {https://doi.org/10.1016/j.cpc.2022.108515},
  url      = {https://www.sciencedirect.com/science/article/pii/S001046552200234X},
  author   = {Qi Zhang and Chaoxuan Gu and Jingyi Zhuang and Renata M. Wentzcovitch},
  keywords = {automation, workflow, high-level, high-throughput, data lineage}
}
```

We also have an [arXiv prepint](https://arxiv.org/abs/2109.11724).

## Installation

The package can be installed with the Julia package manager.
From [the Julia REPL](https://docs.julialang.org/en/v1/stdlib/REPL/), type `]` to enter
the [Pkg mode](https://docs.julialang.org/en/v1/stdlib/REPL/#Pkg-mode) and run:

```julia-repl
pkg> add SimpleWorkflows
```

Or, equivalently, via [`Pkg.jl`](https://pkgdocs.julialang.org/v1/):

```@repl
import Pkg; Pkg.add("SimpleWorkflows")
```

## Documentation

- [**STABLE**](https://MineralsCloud.github.io/SimpleWorkflows.jl/stable) — **documentation of the most recently tagged version.**
- [**DEV**](https://MineralsCloud.github.io/SimpleWorkflows.jl/dev) — _documentation of the in-development version._

## Project status

The package is developed for and tested against Julia `v1.6` and above on Linux, macOS, and
Windows.

## Questions and contributions

You can post usage questions on
[our discussion page](https://github.com/MineralsCloud/SimpleWorkflows.jl/discussions).

We welcome contributions, feature requests, and suggestions. If you encounter any problems,
please open an [issue](https://github.com/MineralsCloud/SimpleWorkflows.jl/issues).
The [Contributing](@ref) page has
a few guidelines that should be followed when opening pull requests and contributing code.

## Manual outline

```@contents
Pages = [
    "man/installation.md",
    "man/portability.md",
    "man/troubleshooting.md",
    "developers/contributing.md",
    "developers/style-guide.md",
    "developers/design-principles.md",
]
Depth = 3
```

## Library outline

```@contents
Pages = ["lib/public.md", "lib/internals.md"]
```

### [Index](@id main-index)

```@index
Pages = ["lib/public.md"]
```
