using Distributed: nprocs, workers
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
struct ParallelExecutor <: Executor
    workers::Vector{UInt64}
    maxattempts::UInt64
    interval::Real
    delay::Real
    wait::Bool
end
function ParallelExecutor(wks=workers(); maxattempts=1, interval=1, delay=0, wait=false)
    @assert 1 <= maximum(wks) <= nprocs()
    @assert maxattempts >= 1
    @assert interval >= zero(interval)
    @assert delay >= zero(delay)
    return ParallelExecutor(wks, maxattempts, interval, delay, wait)
end

"""
    run!(wf::Workflow; maxattempts=5, interval=1, delay=0)

Run a `Workflow` with maximum number of attempts, with each attempt separated by a few seconds.
"""
run!(wf::AbstractWorkflow; kwargs...) = execute!(wf, AsyncExecutor(; kwargs...))
run!(wf::AbstractWorkflow, workers::Vector; kwargs...) =
    execute!(wf, ParallelExecutor(workers; kwargs...))

"""
    execute!(workflow::AbstractWorkflow, exec::Executor)

Executes the jobs from the workflow of the provided Executor instance.

The function will attempt to execute all the jobs up to `exec.maxattempts` times. If all jobs
have succeeded, the function will stop immediately. Otherwise, it will wait for a duration equal
to `exec.interval` before the next attempt.
"""
function execute!(wf::AbstractWorkflow, exec::Executor)
    task = if issucceeded(wf)
        @task wf  # Just return the job if it has succeeded
    else
        sleep(exec.delay)
        @task dispatch!(wf, exec)
    end
    schedule(task)
    if exec.wait
        wait(task)
    end
    return task
end

function dispatch!(wf::AbstractWorkflow, exec::SerialExecutor)
    for _ in Base.OneTo(exec.maxattempts)
        for job in Iterators.filter(!issucceeded, wf)
            run!(job; maxattempts=1, interval=0, delay=0, wait=true)  # Must wait for serial execution
        end
        issucceeded(wf) ? break : sleep(exec.interval)
    end
    return wf
end
function dispatch!(wf::AbstractWorkflow, exec::AsyncExecutor)
    for _ in Base.OneTo(exec.maxattempts)
        jobs, graph = copy(wf.jobs), copy(wf.graph)
        run_kahn_algo!(jobs, graph)
        issucceeded(wf) ? break : sleep(exec.interval)
    end
    return wf
end
function dispatch!(wf::AbstractWorkflow, exec::ParallelExecutor)
    for _ in Base.OneTo(exec.maxattempts)
        jobs, graph, workers = copy(wf.jobs), copy(wf.graph), copy(exec.workers)
        run_kahn_algo2!(jobs, graph, workers)
        issucceeded(wf) ? break : sleep(exec.interval)
    end
    return wf
end

# This function `run_kahn_algo!` is an implementation of Kahn's algorithm for job scheduling.
# `graph` is a directed acyclic graph representing dependencies between jobs.
# `execs` is a list of executors that can run the jobs.
function run_kahn_algo!(jobs, graph)  # Do not export!
    # Check if `execs` is empty and if there are no vertices in the `graph`.
    # This is the base case of the recursion, if there are no jobs left to execute and no
    # vertices in the graph, the function will stop its execution.
    if isempty(jobs) && iszero(nv(graph))  # Stopping criterion
        return nothing
    elseif length(jobs) == nv(graph)
        # Find all vertices with zero in-degree in the graph, these vertices have no prerequisites
        # and can be executed immediately. They are put in a queue.
        queue = findall(iszero, indegree(graph))
        # For each executor in the `queue`, start the job execution.
        # The `@sync` macro ensures that the main program waits until all async blocks are done.
        @sync for job in jobs[queue]
            # Run the jobs with no prerequisites in parallel since they are in the same level.
            @async run!(job; maxattempts=1, interval=0, delay=0, wait=true)
        end
        # Remove the vertices corresponding to the executed jobs from the graph.
        # This also changes the indegree of the remaining vertices.
        rem_vertices!(graph, queue; keep_order=true)
        # Remove the executed jobs from the list.
        deleteat!(jobs, queue)
        # Recursively call the `run_kahn_algo!` with the updated jobs list and graph.
        # This will continue the execution with the remaining jobs that are now without prerequisites.
        return run_kahn_algo!(jobs, graph)
    else
        throw(ArgumentError("something went wrong when running Kahn's algorithm!"))
    end
end
function run_kahn_algo2!(jobs, graph, workers)  # Do not export!
    if isempty(jobs) && iszero(nv(graph)) && isempty(workers)  # Stopping criterion
        return nothing
    elseif length(jobs) == nv(graph) == length(workers)
        queue = findall(iszero, indegree(graph))
        @sync for (job, worker) in zip(jobs[queue], workers)
            @async run!(job, worker; maxattempts=1, interval=0, delay=0, wait=true)
        end
        rem_vertices!(graph, queue; keep_order=true)
        deleteat!(jobs, queue)
        deleteat!(workers, queue)
        return run_kahn_algo!(jobs, graph, workers)
    else
        throw(ArgumentError("something went wrong when running Kahn's algorithm!"))
    end
end
