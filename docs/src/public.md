```@meta
CurrentModule = SimpleWorkflows
```

# Library

```@contents
Pages = ["public.md"]
```

```@meta
CurrentModule = SimpleWorkflows
```

## `Workflows` module

```@docs
Workflow
run!(::Workflow)
getstatus(::Workflow)
chain
→
←
thread
⇶
⬱
fork
converge
spindle
pendingjobs(::Workflow)
runningjobs(::Workflow)
exitedjobs(::Workflow)
succeededjobs(::Workflow)
failedjobs(::Workflow)
interruptedjobs(::Workflow)
```
