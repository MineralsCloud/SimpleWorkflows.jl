```@meta
CurrentModule = SimpleWorkflows
```

# API

```@contents
Pages = ["api.md"]
```

## Jobs

### Public interfaces

```@docs
Job
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

### Public interfaces

```@docs
Workflow
chain
fork
converge
diamond
```
