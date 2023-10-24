using MetaGraphs: MetaDiGraph, get_prop, set_prop!

import EasyJobsBase:
    getstatus,
    ispending,
    isrunning,
    isexited,
    issucceeded,
    isfailed,
    listpending,
    listrunning,
    listexited,
    listsucceeded,
    listfailed

export getstatus,
    ispending,
    isrunning,
    isexited,
    issucceeded,
    isfailed,
    liststatus,
    listpending,
    listrunning,
    listexited,
    listsucceeded,
    listfailed

"""
    getstatus(wf::AbstractWorkflow)

Get the current status of jobs in a `AbstractWorkflow` as a graph.
"""
function getstatus(wf::Workflow)
    graph = MetaDiGraph(wf.graph)
    for (i, job) in enumerate(wf.jobs)
        set_prop!(graph, i, :status, getstatus(job))
    end
    return graph
end

"""
    liststatus(wf::AbstractWorkflow)

List the current status of jobs in a `AbstractWorkflow` as a vector.

See also [`getstatus`](@ref).
"""
liststatus(wf::AbstractWorkflow) =
    collect(get_prop(getstatus(wf), i, :status) for i in 1:nv(getstatus(wf)))

"""
    ispending(wf::AbstractWorkflow)

Check if all jobs in the `AbstractWorkflow` are in a pending state.

Return `true` if all jobs are pending, otherwise, return `false`.
"""
ispending(wf::AbstractWorkflow) = all(ispending, wf)

"""
    isrunning(wf::AbstractWorkflow)

Check if any job in the `AbstractWorkflow` is currently running.

Return `true` if at least one job is running, otherwise, return `false`.
"""
isrunning(wf::AbstractWorkflow) = any(isrunning, wf)

"""
    isexited(wf::AbstractWorkflow)

Check if all jobs in the `AbstractWorkflow` have exited.

Return `true` if all jobs have exited, otherwise, return `false`.
"""
isexited(wf::AbstractWorkflow) = all(isexited, wf)

"""
    issucceeded(wf::AbstractWorkflow)

Check if all jobs in the `AbstractWorkflow` have successfully completed.

Return `true` if all jobs have succeeded, otherwise, return `false`.
"""
issucceeded(wf::AbstractWorkflow) = all(issucceeded, wf)

"""
    isfailed(wf::AbstractWorkflow)

Check if any job in the `AbstractWorkflow` has failed, given that all jobs have exited.

Return `true` if any job has failed after all jobs have exited, otherwise, return `false`.
"""
isfailed(wf::AbstractWorkflow) = isexited(wf) && any(isfailed, wf)

# See https://docs.julialang.org/en/v1/manual/documentation/#Advanced-Usage
for (func, adj) in zip(
    (:listpending, :listrunning, :listexited, :listsucceeded, :listfailed),
    ("pending", "running", "exited", "succeeded", "failed"),
)
    name = string(func)
    @eval begin
        """
            $($name)(wf::AbstractWorkflow)

        Filter only the $($adj) jobs in a `Workflow`.
        """
        $func(wf::Workflow) = $func(wf)
    end
end
