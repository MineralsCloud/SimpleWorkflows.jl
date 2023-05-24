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

function run_kahn_algo!(wf, jobs, graph; δt)  # Do not export!
    if isempty(jobs) && iszero(nv(graph))  # Stopping criterion
        return nothing
    elseif isempty(jobs) && !iszero(nv(graph)) || !isempty(jobs) && iszero(nv(graph))
        throw(
            ArgumentError(
                "either `jobs` is empty but `graph` is not, or `graph` is empty but `jobs` is not!",
            ),
        )
    else
        queue = findall(iszero, indegree(graph))
        @sync for job in jobs[queue]
            @async begin
                exec = run!(job; maxattempts=1, interval=δt, waitfor=0)  # Only run once for each job
                wait(exec)
                save(wf)
            end
        end
        rem_vertices!(graph, queue; keep_order=true)
        deleteat!(jobs, queue)
        return run_kahn_algo!(wf, jobs, graph; δt=δt)
    end
end

getjobs(wf::Workflow) = wf.jobs
getjobs(wf::AutosaveWorkflow) = getjobs(wf.wf)

getgraph(wf::Workflow) = wf.graph
getgraph(wf::AutosaveWorkflow) = getgraph(wf.wf)

save(::Workflow) = nothing
save(wf::AutosaveWorkflow) = serialize(wf.path, wf.wf)
