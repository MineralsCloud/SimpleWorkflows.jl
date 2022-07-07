```@meta
CurrentModule = SimpleWorkflows
```

# SimpleWorkflows

Documentation for [SimpleWorkflows](https://github.com/MineralsCloud/SimpleWorkflows.jl).

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

- [**STABLE**](https://MineralsCloud.github.io/SimpleWorkflows.jl/stable) &mdash; **documentation of the most recently tagged version.**
- [**DEV**](https://MineralsCloud.github.io/SimpleWorkflows.jl/dev) &mdash; *documentation of the in-development version.*

## Project Status

The package is tested against, and being developed for, Julia `1.6` and above on Linux,
macOS, and Windows.

## Questions and Contributions

Usage questions can be posted on
[our discussion page](https://github.com/MineralsCloud/SimpleWorkflows.jl/discussions).

Contributions are very welcome, as are feature requests and suggestions. Please open an
[issue](https://github.com/MineralsCloud/SimpleWorkflows.jl/issues)
if you encounter any problems. The [contributing](@ref) page has
a few guidelines that should be followed when opening pull requests and contributing code.

## Manual Outline

```@contents
Pages = [
    "installation.md",
    "contributing.md",
]
Depth = 3
```

## Library Outline

```@contents
Pages = ["public.md"]
```

### [Index](@id main-index)

```@index
Pages = ["public.md"]
```
