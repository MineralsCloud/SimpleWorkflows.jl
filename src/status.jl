using MetaGraphs: MetaDiGraph, get_prop, set_prop!

import EasyJobsBase:
    getstatus,
    ispending,
    isrunning,
    isexited,
    issucceeded,
    isfailed,
    isinterrupted,
    listpending,
    listrunning,
    listexited,
    listsucceeded,
    listfailed,
    listinterrupted

export getstatus,
    ispending,
    isrunning,
    isexited,
    issucceeded,
    isfailed,
    isinterrupted,
    liststatus,
    listpending,
    listrunning,
    listexited,
    listsucceeded,
    listfailed,
    listinterrupted

"""
    getstatus(wf::AbstractWorkflow)

Get the current status of `Job`s in a `AbstractWorkflow` as a graph.
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

List the current status of `Job`s in a `AbstractWorkflow` as a vector.

See also [`getstatus`](@ref).
"""
liststatus(wf::AbstractWorkflow) =
    collect(get_prop(getstatus(wf), i, :status) for i in 1:nv(getstatus(wf)))

ispending(wf::AbstractWorkflow) = all(ispending, eachjob(wf))

isrunning(wf::AbstractWorkflow) = any(isrunning, eachjob(wf))

isexited(wf::AbstractWorkflow) = all(isexited, eachjob(wf))

issucceeded(wf::AbstractWorkflow) = all(issucceeded, eachjob(wf))

isfailed(wf::AbstractWorkflow) = isexited(wf) && any(isfailed, eachjob(wf))

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
        $func(wf::Workflow) = $func(eachjob(wf))
    end
end
