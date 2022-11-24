module SimpleWorkflows

using Dates: format
using EasyJobsBase.Thunks: printfunc
using EasyJobsBase: AbstractJob, ispending, isrunning, starttime, stoptime, elapsed
using Graphs: DiGraph, add_edge!, nv, is_cyclic, is_connected, has_edge

export Workflow, AutosaveWorkflow

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
        return new(jobs, graph)
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
        neighbors = vcat(job.parents, job.children)
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

"""
    AutosaveWorkflow(path, jobs::AbstractJob...)

Create a `AutosaveWorkflow` from a given series of `Job`s and a `path`.

When running, the status of the workflow will be automatically saved to `path`.
"""
struct AutosaveWorkflow{T} <: AbstractWorkflow
    path::T
    wf::Workflow
end
AutosaveWorkflow(path, jobs::AbstractJob...) = AutosaveWorkflow(path, Workflow(jobs...))

function Base.show(io::IO, wf::Workflow)
    if get(io, :compact, false) || get(io, :typeinfo, nothing) == typeof(wf)
        Base.show_default(IOContext(io, :limit => true), wf)  # From https://github.com/mauro3/Parameters.jl/blob/ecbf8df/src/Parameters.jl#L556
    else
        println(io, summary(wf))
        println(io, " jobs:")
        for (i, job) in enumerate(wf.jobs)
            println(io, "  (", i, ") ", "id: ", job.id)
            if !isempty(job.description)
                print(io, ' '^6, "description: ")
                show(io, job.description)
                println(io)
            end
            print(io, ' '^6, "def: ")
            printfunc(io, job.core)
            print(io, '\n', ' '^6, "status: ")
            printstyled(io, getstatus(job); bold=true)
            if !ispending(job)
                print(
                    io,
                    '\n',
                    ' '^6,
                    "from: ",
                    format(starttime(job), "dd-u-YYYY HH:MM:SS.s"),
                    '\n',
                    ' '^6,
                    "to: ",
                )
                if isrunning(job)
                    print(io, "still running...")
                else
                    println(io, format(stoptime(job), "dd-u-YYYY HH:MM:SS.s"))
                    print(io, ' '^6, "uses: ", elapsed(job))
                end
            end
            println(io)
        end
    end
end
function Base.show(io::IO, wf::AutosaveWorkflow)
    if get(io, :compact, false) || get(io, :typeinfo, nothing) == typeof(wf)
        Base.show_default(IOContext(io, :limit => true), wf)  # From https://github.com/mauro3/Parameters.jl/blob/ecbf8df/src/Parameters.jl#L556
    else
        print(io, "Autosave", wf.wf)
        println(io, " path: ", wf.path)
    end
end

include("run!.jl")
include("status.jl")

end
