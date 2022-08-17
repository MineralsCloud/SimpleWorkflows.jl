module Jobs

using Dates: DateTime, now, format
using UUIDs: UUID, uuid1

using ..Thunks: Thunk, printfunc

export Job

@enum JobStatus begin
    PENDING
    RUNNING
    SUCCEEDED
    FAILED
    INTERRUPTED
end

# Reference: https://github.com/cihga39871/JobSchedulers.jl/blob/aca52de/src/jobs.jl#L35-L69
"""
    Job(thunk::Thunk; desc="", user="")

Create a simple job.

# Arguments
- `thunk`: a `Thunk` that encloses the job definition.
- `desc::String=""`: describe briefly what this job does.
- `user::String=""`: indicate who executes this job.

```@example
a = Job(Thunk(sleep)(5); user="me", desc="Sleep for 5 seconds")
b = Job(Thunk(run, `pwd` & `ls`); user="me", desc="Run some commands")
```
"""
mutable struct Job
    id::UUID
    thunk::Thunk
    desc::String
    user::String
    created_time::DateTime
    start_time::DateTime
    stop_time::DateTime
    "Track the job status."
    status::JobStatus
    count::UInt64
    "These jobs runs before the current job."
    parents::Vector{Job}
    "These jobs runs after the current job."
    children::Vector{Job}
    Job(thunk::Thunk; desc = "", user = "") =
        new(uuid1(), thunk, desc, user, now(), DateTime(0), DateTime(0), PENDING, 0, [], [])
end
"""
    Job(job::Job)

Create a new `Job` from an existing `Job`.
"""
Job(job::Job) = Job(
    job.thunk;
    desc = job.desc,
    user = job.user,
    parents = job.parents,
    children = job.children,
)

function Base.show(io::IO, job::Job)
    if get(io, :compact, false) || get(io, :typeinfo, nothing) == typeof(job)
        Base.show_default(IOContext(io, :limit => true), job)  # From https://github.com/mauro3/Parameters.jl/blob/ecbf8df/src/Parameters.jl#L556
    else
        println(io, summary(job))
        println(io, ' ', "id: ", job.id)
        if !isempty(job.desc)
            print(io, ' ', "description: ")
            show(io, job.desc)
            println(io)
        end
        print(io, ' ', "def: ")
        printfunc(io, job.thunk)
        print(io, '\n', ' ', "status: ")
        printstyled(io, getstatus(job); bold = true)
        if !ispending(job)
            println(io, '\n', ' ', "from: ", format(starttime(job), "dd-u-YYYY HH:MM:SS.s"))
            print(io, ' ', "to: ")
            if isrunning(job)
                print(io, "still running...")
            else
                println(io, format(stoptime(job), "dd-u-YYYY HH:MM:SS.s"))
                print(io, ' ', "uses: ", elapsed(job))
            end
        end
    end
end

include("run!.jl")
include("registry.jl")
include("status.jl")
include("misc.jl")

end
