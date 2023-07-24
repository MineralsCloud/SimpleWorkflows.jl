module SimpleWorkflows

using EasyJobsBase: AbstractJob
using Graphs:
    DiGraph, add_edge!, nv, is_cyclic, is_connected, has_edge, topological_sort_by_dfs

export Workflow, findjob

abstract type AbstractWorkflow end

# Create a `Workflow` from a list of `AbstractJob`s and a graph representing their relations.
struct Workflow <: AbstractWorkflow
    jobs::Vector{AbstractJob}
    graph::DiGraph{Int}
    function Workflow(jobs, graph)
        @assert !is_cyclic(graph) "`graph` must be acyclic"
        @assert is_connected(graph) "`graph` must be connected!"
        @assert nv(graph) == length(jobs) "`graph` has different size from `jobs`!"
        @assert allunique(jobs) "at least two jobs are identical!"
        order = topological_sort_by_dfs(graph)
        reordered_jobs = collect(jobs[order])
        n = length(reordered_jobs)
        new_graph = DiGraph(n)
        dict = IdDict(zip(reordered_jobs, 1:n))
        # You must sort the graph too for `DependentJob`s to run in the correct order!
        for (i, job) in enumerate(reordered_jobs)
            for parent in job.parents
                if !has_edge(new_graph, dict[parent], i)
                    add_edge!(new_graph, dict[parent], i)
                end
            end
            for child in job.children
                if !has_edge(new_graph, i, dict[child])
                    add_edge!(new_graph, i, dict[child])
                end
            end
        end
        return new(reordered_jobs, new_graph)
    end
end
"""
    Workflow(jobs::AbstractJob...)

Create a `Workflow` from a given series of `AbstractJob`s.

The list of `AbstractJob`s does not have to be complete, our algorithm will find all
connected `AbstractJob`s automatically.
"""
function Workflow(jobs::AbstractJob...)
    foundjobs = convert(Vector{AbstractJob}, collect(jobs))  # Need to relax type constraints to contain different types of jobs
    for job in foundjobs
        neighbors = union(job.parents, job.children)
        for neighbor in neighbors
            if neighbor ∉ foundjobs
                push!(foundjobs, neighbor)  # This will alter `all_possible_jobs` dynamically
            end
        end
    end
    n = length(foundjobs)
    graph = DiGraph(n)
    dict = IdDict(zip(foundjobs, 1:n))
    for (i, job) in enumerate(foundjobs)
        for parent in job.parents
            if !has_edge(graph, dict[parent], i)
                add_edge!(graph, dict[parent], i)
            end
        end
        for child in job.children
            if !has_edge(graph, i, dict[child])
                add_edge!(graph, i, dict[child])
            end
        end
    end
    return Workflow(foundjobs, graph)
end

function findjob(wf::Workflow, id)
    for (i, job) in enumerate(eachjob(wf))
        if job.id == id
            return i
        end
    end
    return nothing
end
findjob(wf::Workflow, job::AbstractJob) = findjob(wf, job.id)

Base.in(job::AbstractJob, wf::Workflow) = job in eachjob(wf)

listjobs(wf::Workflow) = wf.jobs

include("eachjob.jl")
include("operations.jl")
include("run.jl")
include("status.jl")
include("show.jl")

end
