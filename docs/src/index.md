```@meta
CurrentModule = SimpleWorkflows
```

# SimpleWorkflows

Documentation for [SimpleWorkflows](https://github.com/MineralsCloud/SimpleWorkflows.jl).

Build workflows from jobs. Run, monitor, and get results from them.

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

See the [Index](@ref main-index) for the complete list of documented functions
and types.

The code is [hosted on GitHub](https://github.com/MineralsCloud/SimpleWorkflows.jl),
with some continuous integration services to test its validity.

This repository is created and maintained by [@singularitti](https://github.com/singularitti).
You are very welcome to contribute.

## Installation

The package can be installed with the Julia package manager.
From the Julia REPL, type `]` to enter the Pkg REPL mode and run:

```julia
pkg> add SimpleWorkflows
```

Or, equivalently, via the `Pkg` API:

```@repl
import Pkg; Pkg.add("SimpleWorkflows")
```

## Documentation

- [**STABLE**](https://MineralsCloud.github.io/SimpleWorkflows.jl/stable) — **documentation of the most recently tagged version.**
- [**DEV**](https://MineralsCloud.github.io/SimpleWorkflows.jl/dev) — _documentation of the in-development version._

## Project status

The package is tested against, and being developed for, Julia `1.6` and above on Linux,
macOS, and Windows.

## Questions and contributions

Usage questions can be posted on
[our discussion page](https://github.com/MineralsCloud/SimpleWorkflows.jl/discussions).

Contributions are very welcome, as are feature requests and suggestions. Please open an
[issue](https://github.com/MineralsCloud/SimpleWorkflows.jl/issues)
if you encounter any problems. The [Contributing](@ref) page has
a few guidelines that should be followed when opening pull requests and contributing code.

## Manual outline

```@contents
Pages = [
    "installation.md",
    "portability.md",
    "developers/contributing.md",
    "developers/style-guide.md",
    "developers/design-principles.md",
    "troubleshooting.md",
]
Depth = 3
```

## Library outline

```@contents
Pages = ["public.md"]
```

### [Index](@id main-index)

```@index
Pages = ["public.md"]
```
