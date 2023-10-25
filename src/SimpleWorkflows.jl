module SimpleWorkflows

using EasyJobsBase: AbstractJob, eachparent, eachchild
using Graphs:
    DiGraph,
    add_edge!,
    nv,
    is_cyclic,
    is_directed,
    is_connected,
    has_edge,
    topological_sort_by_dfs

export Workflow

abstract type AbstractWorkflow end

# Create a `Workflow` from a list of `AbstractJob`s and a graph representing their relations.
struct Workflow{T} <: AbstractWorkflow
    jobs::Vector{T}
    graph::DiGraph{Int64}
    function Workflow(jobs, graph)
        @assert !is_cyclic(graph) "`graph` must be acyclic!"
        @assert is_directed(graph) "`graph` must be directed!"
        @assert is_connected(graph) "`graph` must be connected!"
        @assert nv(graph) == length(jobs) "`graph` has different size from `jobs`!"
        @assert allunique(jobs) "at least two jobs are identical!"
        order = topological_sort_by_dfs(graph)
        sorted_jobs = collect(jobs[order])
        n = length(sorted_jobs)
        new_graph = DiGraph(n)
        dict = IdDict(zip(sorted_jobs, 1:n))
        # You must sort the graph too for `DependentJob`s to run in the correct order!
        for (i, job) in enumerate(sorted_jobs)
            for parent in eachparent(job)
                if !has_edge(new_graph, dict[parent], i)
                    add_edge!(new_graph, dict[parent], i)
                end
            end
            for child in eachchild(job)
                if !has_edge(new_graph, i, dict[child])
                    add_edge!(new_graph, i, dict[child])
                end
            end
        end
        return new{eltype(sorted_jobs)}(sorted_jobs, new_graph)
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
        neighbors = union(eachparent(job), eachchild(job))
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
        for parent in eachparent(job)
            if !has_edge(graph, dict[parent], i)
                add_edge!(graph, dict[parent], i)
            end
        end
        for child in eachchild(job)
            if !has_edge(graph, i, dict[child])
                add_edge!(graph, i, dict[child])
            end
        end
    end
    return Workflow(foundjobs, graph)
end

Base.indexin(jobs, wf::Workflow) = Base.indexin(jobs, collect(wf))

Base.in(job::AbstractJob, wf::Workflow) = job in wf.jobs

Base.iterate(wf::Workflow, state=firstindex(wf)) = iterate(wf.jobs, state)

Base.eltype(::Type{Workflow{T}}) where {T} = T

Base.length(wf::Workflow) = length(wf.jobs)

Base.getindex(wf::Workflow, i) = getindex(wf.jobs, i)

Base.firstindex(wf::Workflow) = 1

Base.lastindex(wf::Workflow) = length(wf.jobs)

include("operations.jl")
include("run.jl")
include("status.jl")
include("show.jl")

end
