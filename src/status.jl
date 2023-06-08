using MetaGraphs: MetaDiGraph, get_prop, set_prop!

import EasyJobsBase:
    getstatus,
    listpending,
    listrunning,
    listexited,
    listsucceeded,
    listfailed,
    listinterrupted

export getstatus,
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
getstatus(wf::AutosaveWorkflow) = getstatus(wf.wf)

"""
    liststatus(wf::AbstractWorkflow)

List the current status of `Job`s in a `AbstractWorkflow` as a vector.

See also [`getstatus`](@ref).
"""
liststatus(wf::AbstractWorkflow) =
    collect(get_prop(getstatus(wf), i, :status) for i in 1:nv(getstatus(wf)))

# See https://docs.julialang.org/en/v1/manual/documentation/#Advanced-Usage
for (func, adj) in zip(
    (
        :listpending,
        :listrunning,
        :listexited,
        :listsucceeded,
        :listfailed,
        :listinterrupted,
    ),
    ("pending", "running", "exited", "succeeded", "failed", "interrupted"),
)
    name = string(func)
    @eval begin
        """
            $($name)(wf::AbstractWorkflow)

        Filter only the $($adj) jobs in a `Workflow`.
        """
        $func(wf::Workflow) = $func(wf.jobs)
        $func(wf::AutosaveWorkflow) = $func(wf.wf)
    end
end
