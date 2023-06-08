using EasyJobsBase: Executor as JobExecutor, issucceeded
using Graphs: indegree, rem_vertices!
using Serialization: serialize

import EasyJobsBase: run!, execute!

export run!, execute!

struct Executor{T<:AbstractWorkflow}
    wf::T
    maxattempts::UInt64
    interval::Real
    waitfor::Real
    jobexecutors::Vector{JobExecutor}
    function Executor(wf::T; maxattempts=1, interval=1, waitfor=0, jobinterval=1) where {T}
        @assert maxattempts >= 1
        @assert interval >= zero(interval)
        @assert waitfor >= zero(waitfor)
        jobexecutors = collect(
            JobExecutor(job; maxattempts=1, interval=jobinterval, waitfor=0) for
            job in wf.jobs
        )
        return new{T}(wf, maxattempts, interval, waitfor, jobexecutors)
    end
end

"""
    run!(wf::Workflow; n=5, δt=1, Δt=1)

Run a `Workflow` with maximum `n` attempts, with each attempt separated by `Δt` seconds.

Cool down for `δt` seconds after each `Job` in the `Workflow`.
"""
function run!(wf::AbstractWorkflow; kwargs...)
    exec = Executor(wf; kwargs...)
    execute!(exec)
    return exec
end

function execute!(exec::Executor)
    save(exec.wf)
    for _ in Base.OneTo(exec.maxattempts)
        if any(!issucceeded(job) for job in getjobs(exec))
            # This separation is necessary, since `run_kahn_algo!` modfiies the graph.
            execs = collect(
                JobExecutor(job; maxattempts=1, interval=0, waitfor=0) for job in wf.jobs
            )  # Job executors
            graph = copy(getgraph(exec.wf))
            run_kahn_algo!(wf, execs, graph)
            return exec
        end
        if all(issucceeded(job) for job in getjobs(exec))
            break  # Stop immediately
        else
            sleep(exec.interval)
        end
    end
    return exec
end

# This function `run_kahn_algo!` is an implementation of Kahn's algorithm for job scheduling.
# `wf` is a workflow that will be saved after each job execution.
# `graph` is a directed acyclic graph representing dependencies between jobs.
# `execs` is a list of executors that can run the jobs.
function run_kahn_algo!(wf, execs, graph)  # Do not export!
    # Check if `execs` is empty and if there are no vertices in the `graph`.
    # This is the base case of the recursion, if there are no jobs left to execute and no
    # vertices in the graph, the function will stop its execution.
    if isempty(execs) && iszero(nv(graph))  # Stopping criterion
        return nothing
    elseif isempty(execs) && !iszero(nv(graph))
        throw(ArgumentError("`execs` is empty but `graph` is not! This should not happen!"))
    elseif !isempty(execs) && iszero(nv(graph))
        throw(ArgumentError("`graph` is empty but `execs` is not! This should not happen!"))
    else
        # Find all vertices with zero in-degree in the graph, these vertices have no prerequisites
        # and can be executed immediately. They are put in a queue.
        queue = findall(iszero, indegree(graph))
        # For each executor in the `queue`, start the job execution.
        # The `@sync` macro ensures that the main program waits until all async blocks are done.
        @sync for exec in execs[queue]
            # Run the jobs with no prerequisites in parallel since they are in the same level.
            @async begin
                execute!(exec)
                wait(exec)
                save(wf)
            end
        end
        # Remove the vertices corresponding to the executed jobs from the graph.
        # This also changes the indegree of the remaining vertices.
        rem_vertices!(graph, queue; keep_order=true)
        # Remove the executed jobs from the list.
        deleteat!(execs, queue)
        # Recursively call the `run_kahn_algo!` with the updated jobs list and graph.
        # This will continue the execution with the remaining jobs that are now without prerequisites.
        return run_kahn_algo!(wf, execs, graph)
    end
end

getjobs(wf::Workflow) = wf.jobs
getjobs(wf::AutosaveWorkflow) = getjobs(wf.wf)

getgraph(wf::Workflow) = wf.graph
getgraph(wf::AutosaveWorkflow) = getgraph(wf.wf)

save(::Workflow) = nothing
save(wf::AutosaveWorkflow) = serialize(wf.path, wf.wf)
