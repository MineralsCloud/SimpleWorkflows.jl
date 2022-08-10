```@meta
CurrentModule = SimpleWorkflows
```

# Library

```@contents
Pages = ["public.md"]
```

## Jobs

```@docs
Job
@job
getresult
getstatus(x::Job)
ispending
isrunning
isexited
issucceeded
isfailed
isinterrupted
createdtime
starttime
stoptime
elapsed
description
run!(job::Job; n=1, δt=1)
interrupt!
queue
query
ntimes
```

## Workflows

```@docs
Workflow
run!(wf::Workflow; n=5, δt=1, Δt=1, filename="saved.jld2")
getstatus(wf::Workflow)
chain
→
←
thread
⇶
⬱
fork
converge
spindle
```
