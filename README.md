<div align="center">
  <img src="https://raw.githubusercontent.com/MineralsCloud/SimpleWorkflows.jl/main/docs/src/assets/logo.png" height="200"><br>
</div>

# SimpleWorkflows

|                                 **Documentation**                                  |                                                                                                 **Build Status**                                                                                                 |                                        **Others**                                         |
| :--------------------------------------------------------------------------------: | :--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------: | :---------------------------------------------------------------------------------------: |
| [![Stable][docs-stable-img]][docs-stable-url] [![Dev][docs-dev-img]][docs-dev-url] | [![Build Status][gha-img]][gha-url] [![Build Status][appveyor-img]][appveyor-url] [![Build Status][cirrus-img]][cirrus-url] [![pipeline status][gitlab-img]][gitlab-url] [![Coverage][codecov-img]][codecov-url] | [![GitHub license][license-img]][license-url] [![Code Style: Blue][style-img]][style-url] |

[docs-stable-img]: https://img.shields.io/badge/docs-stable-blue.svg
[docs-stable-url]: https://MineralsCloud.github.io/SimpleWorkflows.jl/stable
[docs-dev-img]: https://img.shields.io/badge/docs-dev-blue.svg
[docs-dev-url]: https://MineralsCloud.github.io/SimpleWorkflows.jl/dev
[gha-img]: https://github.com/MineralsCloud/SimpleWorkflows.jl/workflows/CI/badge.svg
[gha-url]: https://github.com/MineralsCloud/SimpleWorkflows.jl/actions
[appveyor-img]: https://ci.appveyor.com/api/projects/status/github/MineralsCloud/SimpleWorkflows.jl?svg=true
[appveyor-url]: https://ci.appveyor.com/project/singularitti/SimpleWorkflows-jl
[cirrus-img]: https://api.cirrus-ci.com/github/MineralsCloud/SimpleWorkflows.jl.svg
[cirrus-url]: https://cirrus-ci.com/github/MineralsCloud/SimpleWorkflows.jl
[gitlab-img]: https://gitlab.com/singularitti/SimpleWorkflows.jl/badges/main/pipeline.svg
[gitlab-url]: https://gitlab.com/singularitti/SimpleWorkflows.jl/-/pipelines
[codecov-img]: https://codecov.io/gh/MineralsCloud/SimpleWorkflows.jl/branch/main/graph/badge.svg
[codecov-url]: https://codecov.io/gh/MineralsCloud/SimpleWorkflows.jl
[license-img]: https://img.shields.io/github/license/MineralsCloud/SimpleWorkflows.jl
[license-url]: https://github.com/MineralsCloud/SimpleWorkflows.jl/blob/main/LICENSE
[style-img]: https://img.shields.io/badge/code%20style-blue-4495d1.svg
[style-url]: https://github.com/invenia/BlueStyle

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

```julia
julia> import Pkg; Pkg.add("SimpleWorkflows")
```

## Documentation

- [**STABLE**][docs-stable-url] — **documentation of the most recently tagged version.**
- [**DEV**][docs-dev-url] — _documentation of the in-development version._

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
