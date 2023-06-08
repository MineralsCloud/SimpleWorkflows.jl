using EasyJobsBase: issucceeded
using Graphs: indegree, rem_vertices!
using Serialization: serialize

import EasyJobsBase: run!

export run!

"""
    run!(wf::Workflow; n=5, δt=1, Δt=1)

Run a `Workflow` with maximum `n` attempts, with each attempt separated by `Δt` seconds.

Cool down for `δt` seconds after each `Job` in the `Workflow`.
"""
function run!(wf::AbstractWorkflow; n=5, δt=1, Δt=1)
    @assert isinteger(n) && n >= 1
    save(wf)
    for _ in 1:n
        if any(!issucceeded(job) for job in getjobs(wf))
            run_copy!(wf; δt=δt)
        end
        if all(issucceeded(job) for job in getjobs(wf))
            break  # Stop immediately
        end
        if !iszero(Δt)  # If still unsuccessful
            sleep(Δt)  # `if-else` is faster than `sleep(0)`
        end
    end
    return wf
end

function run_copy!(wf; δt)  # Do not export!
    jobs, graph = copy(getjobs(wf)), copy(getgraph(wf))  # This separation is necessary, or else we call this every iteration of `run_kahn_algo!`
    run_kahn_algo!(wf, jobs, graph; δt=δt)
    return wf
end

# This function `run_kahn_algo!` is an implementation of Kahn's algorithm for job scheduling.
# `wf` is a workflow that will be saved after each job execution.
# `jobs` is a list of jobs to be executed.
# `graph` is a directed acyclic graph representing dependencies between jobs.
# `execs` is a list of executors that can run the jobs.
function run_kahn_algo!(wf, jobs, graph, execs)  # Do not export!
    # Check if `jobs` is empty and if there are no vertices in the `graph`.
    # This is the base case of the recursion, if there are no jobs left and no vertices in the graph,
    # the function will stop its execution.
    if isempty(jobs) && iszero(nv(graph))  # Stopping criterion
        return nothing
    elseif isempty(jobs) && !iszero(nv(graph))
        throw(ArgumentError("`jobs` is empty but `graph` is not!"))
    elseif !isempty(jobs) && iszero(nv(graph))
        throw(ArgumentError("`graph` is empty but `jobs` is not!"))
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
        # Remove the executed jobs from the jobs list.
        deleteat!(jobs, queue)
        # Recursively call the `run_kahn_algo!` with the updated jobs list and graph.
        # This will continue the execution with the remaining jobs that are now without prerequisites.
        return run_kahn_algo!(wf, jobs, graph, execs)
    end
end

getjobs(wf::Workflow) = wf.jobs
getjobs(wf::AutosaveWorkflow) = getjobs(wf.wf)

getgraph(wf::Workflow) = wf.graph
getgraph(wf::AutosaveWorkflow) = getgraph(wf.wf)

save(::Workflow) = nothing
save(wf::AutosaveWorkflow) = serialize(wf.path, wf.wf)
