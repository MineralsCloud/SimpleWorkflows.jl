```@meta
CurrentModule = SimpleWorkflows
```

# Library

```@contents
Pages = ["public.md"]
```

```@meta
CurrentModule = SimpleWorkflows.Thunks
```

## `Thunks` module

```@docs
Thunk
ErredResult
reify!
getresult(::Thunk)
```

```@meta
CurrentModule = SimpleWorkflows.Jobs
```

## `Jobs` module

```@docs
Job
getresult(::Job)
getstatus(::Job)
ispending
isrunning
isexited
issucceeded
isfailed
isinterrupted
pendingjobs
runningjobs
exitedjobs
succeededjobs
failedjobs
interruptedjobs
createdtime
starttime
stoptime
elapsed
description
run!(::Job)
interrupt!
queue
query
ntimes
```

```@meta
CurrentModule = SimpleWorkflows.Workflows
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
