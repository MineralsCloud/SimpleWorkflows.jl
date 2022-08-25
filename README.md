![logo](https://raw.githubusercontent.com/MineralsCloud/SimpleWorkflows.jl/master/docs/src/assets/logo.png)

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
[gitlab-img]: https://gitlab.com/singularitti/SimpleWorkflows.jl/badges/master/pipeline.svg
[gitlab-url]: https://gitlab.com/singularitti/SimpleWorkflows.jl/-/pipelines
[codecov-img]: https://codecov.io/gh/MineralsCloud/SimpleWorkflows.jl/branch/master/graph/badge.svg
[codecov-url]: https://codecov.io/gh/MineralsCloud/SimpleWorkflows.jl
[license-img]: https://img.shields.io/github/license/MineralsCloud/SimpleWorkflows.jl
[license-url]: https://github.com/MineralsCloud/SimpleWorkflows.jl/blob/master/LICENSE
[style-img]: https://img.shields.io/badge/code%20style-blue-4495d1.svg
[style-url]: https://github.com/invenia/BlueStyle

Build workflows from jobs. Run, monitor, and get results from them.

This package take inspiration from
[`JobSchedulers.jl`](https://github.com/cihga39871/JobSchedulers.jl) and
[`Dispatcher.jl`](https://github.com/invenia/Dispatcher.jl) (unmaintained).

Please cite [this package as](https://arxiv.org/abs/2109.11724):

```bibtex
@misc{zhang2021textttexpress,
      title={$\texttt{express}$: extensible, high-level workflows for swifter $\textit{ab initio}$ materials modeling},
      author={Qi Zhang and Chaoxuan Gu and Jingyi Zhuang and Renata M. Wentzcovitch},
      year={2021},
      eprint={2109.11724},
      archivePrefix={arXiv},
      primaryClass={physics.comp-ph}
}
```

The code is [hosted on GitHub](https://github.com/MineralsCloud/SimpleWorkflows.jl),
with some continuous integration services to test its validity.

This repository is created and maintained by [@singularitti](https://github.com/singularitti).
You are very welcome to contribute.

## Installation

The package can be installed with the Julia package manager.
From the Julia REPL, type `]` to enter the Pkg REPL mode and run:

```
pkg> add SimpleWorkflows
```

Or, equivalently, via the [`Pkg` API](https://pkgdocs.julialang.org/v1/getting-started/):

```julia
julia> import Pkg; Pkg.add("SimpleWorkflows")
```

## Documentation

- [**STABLE**][docs-stable-url] — **documentation of the most recently tagged version.**
- [**DEV**][docs-dev-url] — _documentation of the in-development version._

## Project status

The package is tested against, and being developed for, Julia `1.6` and above on Linux,
macOS, and Windows.

## Questions and contributions

Usage questions can be posted on [our discussion page][discussions-url].

Contributions are very welcome, as are feature requests and suggestions. Please open an
[issue][issues-url] if you encounter any problems. The [contributing](@ref) page has
a few guidelines that should be followed when opening pull requests and contributing code.

[discussions-url]: https://github.com/MineralsCloud/SimpleWorkflows.jl/discussions
[issues-url]: https://github.com/MineralsCloud/SimpleWorkflows.jl/issues
[contrib-url]: https://github.com/MineralsCloud/SimpleWorkflows.jl/discussions
