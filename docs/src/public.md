```@meta
CurrentModule = SimpleWorkflows
```

# Library

```@contents
Pages = ["api.md"]
```

## Jobs

```@docs
Job
@job
getresult
getstatus
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
run!
interrupt!
queue
query
ntimes
```

## Workflows

```@docs
Workflow
chain
fork
converge
diamond
```
