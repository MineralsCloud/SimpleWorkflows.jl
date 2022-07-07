![logo](https://raw.githubusercontent.com/MineralsCloud/SimpleWorkflows.jl/master/docs/src/assets/logo.png)

# SimpleWorkflows

|                                 **Documentation**                                  |                                                                                                 **Build Status**                                                                                                 |                  **LICENSE**                  |
| :--------------------------------------------------------------------------------: | :--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------: | :-------------------------------------------: |
| [![Stable][docs-stable-img]][docs-stable-url] [![Dev][docs-dev-img]][docs-dev-url] | [![Build Status][gha-img]][gha-url] [![Build Status][appveyor-img]][appveyor-url] [![Build Status][cirrus-img]][cirrus-url] [![pipeline status][gitlab-img]][gitlab-url] [![Coverage][codecov-img]][codecov-url] | [![GitHub license][license-img]][license-url] |

Build workflows from atomic jobs. Run and monitor them.

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

## Installation

The package can be installed with the Julia package manager.
From the Julia REPL, type `]` to enter the Pkg REPL mode and run:

```
pkg> add SimpleWorkflows
```

Or, equivalently, via the `Pkg` API:

```julia
julia> import Pkg; Pkg.add("SimpleWorkflows")
```

## Documentation

- [**STABLE**][docs-stable-url] &mdash; **documentation of the most recently tagged version.**
- [**DEVEL**][docs-dev-url] &mdash; _documentation of the in-development version._

## Project Status

The package is tested against, and being developed for, Julia `1.6` and above on Linux,
macOS, and Windows.

## Questions and Contributions

Usage questions can be posted on [our discussion page][discussions-url].

Contributions are very welcome, as are feature requests and suggestions. Please open an
[issue][issues-url] if you encounter any problems. The [contributing](@ref) page has
a few guidelines that should be followed when opening pull requests and contributing code.

[discussions-url]: https://github.com/MineralsCloud/SimpleWorkflows.jl/discussions
[issues-url]: https://github.com/MineralsCloud/SimpleWorkflows.jl/issues
[contrib-url]: https://github.com/MineralsCloud/SimpleWorkflows.jl/discussions
