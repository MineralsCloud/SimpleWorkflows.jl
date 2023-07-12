using EasyJobsBase: Executor as JobExecutor, issucceeded
using Graphs: indegree, rem_vertices!

import EasyJobsBase: run!, execute!

export run!, execute!

abstract type Executor end
struct SerialExecutor <: Executor
    maxattempts::UInt64
    interval::Real
    delay::Real
    wait::Bool
end
function SerialExecutor(; maxattempts=1, interval=1, delay=0, wait=false)
    @assert maxattempts >= 1
    @assert interval >= zero(interval)
    @assert delay >= zero(delay)
    return SerialExecutor(maxattempts, interval, delay, wait)
end
struct AsyncExecutor <: Executor
    maxattempts::UInt64
    interval::Real
    delay::Real
    wait::Bool
end
function AsyncExecutor(; maxattempts=1, interval=1, delay=0, wait=false)
    @assert maxattempts >= 1
    @assert interval >= zero(interval)
    @assert delay >= zero(delay)
    return AsyncExecutor(maxattempts, interval, delay, wait)
end

"""
    run!(wf::Workflow; maxattempts=5, interval=1, delay=0)

Run a `Workflow` with maximum number of attempts, with each attempt separated by a few seconds.
"""
function run!(wf::AbstractWorkflow; kwargs...)
    exec = AsyncExecutor(; kwargs...)
    execute!(wf, exec)
    return exec
end

"""
    execute!(workflow::AbstractWorkflow, exec::Executor)

Executes the jobs from the workflow of the provided Executor instance.

The function will attempt to execute all the jobs up to `exec.maxattempts` times. If all jobs
have succeeded, the function will stop immediately. Otherwise, it will wait for a duration equal
to `exec.interval` before the next attempt.
"""
function execute!(wf::AbstractWorkflow, exec::AsyncExecutor)
    jobs = listjobs(wf)
    for _ in Base.OneTo(exec.maxattempts)
        if !issucceeded(wf)
            # This separation is necessary, since `run_kahn_algo!` modfiies the graph.
            execs = collect(
                JobExecutor(job; maxattempts=1, interval=0, delay=0) for job in jobs
            )  # Job executors
            graph = copy(wf.graph)
            run_kahn_algo!(execs, graph)
            return exec
        end
        issucceeded(wf) ? break : sleep(exec.interval)
    end
    return exec
end

# This function `run_kahn_algo!` is an implementation of Kahn's algorithm for job scheduling.
# `graph` is a directed acyclic graph representing dependencies between jobs.
# `execs` is a list of executors that can run the jobs.
function run_kahn_algo!(execs, graph)  # Do not export!
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
                # The wait function is used here to ensure that the `@async` block does not
                # exit until the task has completed.
                wait(exec)
            end
        end
        # Remove the vertices corresponding to the executed jobs from the graph.
        # This also changes the indegree of the remaining vertices.
        rem_vertices!(graph, queue; keep_order=true)
        # Remove the executed jobs from the list.
        deleteat!(execs, queue)
        # Recursively call the `run_kahn_algo!` with the updated jobs list and graph.
        # This will continue the execution with the remaining jobs that are now without prerequisites.
        return run_kahn_algo!(execs, graph)
    end
end
