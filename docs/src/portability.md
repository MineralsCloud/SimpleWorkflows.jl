# How to save and recover the status of a workflow?

Suppose you have a `Workflow` object defined with the following code:

```@repl wf
using SimpleWorkflows.Thunks: Thunk
using SimpleWorkflows.Jobs: Job
using SimpleWorkflows.Workflows: Workflow, run!, →

function f₁()
   println("Start job `i`!")
   sleep(5)
end
function f₂(n)
   println("Start job `j`!")
   sleep(n)
   exp(2)
end
function f₃(n)
   println("Start job `k`!")
   sleep(n)
end
function f₄()
   println("Start job `l`!")
   run(`sleep 3`)
end
function f₅(n, x)
   println("Start job `m`!")
   sleep(n)
   sin(x)
end
function f₆(n; x = 1)
   println("Start job `n`!")
   sleep(n)
   cos(x)
   run(`pwd` & `ls`)
end
i = Job(Thunk(f₁, ()); user = "me", desc = "i")
j = Job(Thunk(f₂, 3); user = "he", desc = "j")
k = Job(Thunk(f₃, 6); desc = "k")
l = Job(Thunk(f₄, ()); desc = "l", user = "me")
m = Job(Thunk(f₅, 3, 1); desc = "m")
n = Job(Thunk(f₆, 1; x = 3); user = "she", desc = "n")
i → l
j → k → m → n
j → l
k → n
wf = Workflow(k)
```

To save the `Workflow` instance to disk while running in case it failed or is interrupted,
use the `SavedWorkflow` type.

```@repl wf
using SimpleWorkflows.Workflows: SavedWorkflow
swf = SavedWorkflow(wf, "saved.jls")
run!(swf; δt = 0, n = 1)
```

After the above steps are finished, a `saved.jls` file is saved to your local file system.
Then you can close the current Julia session and restart it (which resembles an
interrupted remote session, for example).
To reload the workflow, run:

```julia-repl
julia> using SimpleWorkflows

julia> using Serialization: deserialize

julia> deserialize("saved.jls")
```

And voilà!
