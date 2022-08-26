using Dates: format
using EasyJobs.Thunks: printfunc
using EasyJobs: Job, ispending, isrunning, starttime, stoptime, elapsed
using Graphs: DiGraph, add_edge!, nv, is_cyclic, is_connected, has_edge

export Workflow

"""
    Workflow(jobs, graph)

Create a `Workflow` from a list of `Job`s and a graph representing their relations.
"""
struct Workflow
    jobs::Vector{Job}
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
    Workflow(jobs::Job...)

Create a `Workflow` from a given series of `Job`s.

The list of `Job`s does not have to be complete, our algorithm will find all connected `Job`s
automatically.
"""
function Workflow(jobs::Job...)
    all_possible_jobs = collect(jobs)
    for job in all_possible_jobs
        neighbors = vcat(job.parents, job.children)
        for neighbor in neighbors
            if neighbor ∉ all_possible_jobs
                push!(all_possible_jobs, neighbor)  # This will alter `all_possible_jobs` dynamically
            end
        end
    end
    n = length(all_possible_jobs)
    graph = DiGraph(n)
    dict = IdDict(zip(all_possible_jobs, 1:n))
    for (i, job) in enumerate(all_possible_jobs)
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
    return Workflow(all_possible_jobs, graph)
end

struct SavedWorkflow{T}
    wf::Workflow
    file::T
end

function Base.show(io::IO, wf::Workflow)
    if get(io, :compact, false) || get(io, :typeinfo, nothing) == typeof(wf)
        Base.show_default(IOContext(io, :limit => true), wf)  # From https://github.com/mauro3/Parameters.jl/blob/ecbf8df/src/Parameters.jl#L556
    else
        println(io, summary(wf))
        println(io, ' ', wf.graph)
        println(io, "jobs:")
        for (i, job) in enumerate(wf.jobs)
            println(io, " (", i, ") ", "id: ", job.id)
            if !isempty(job.desc)
                print(io, ' '^5, "description: ")
                show(io, job.desc)
                println(io)
            end
            print(io, ' '^5, "def: ")
            printfunc(io, job.thunk)
            print(io, '\n', ' '^5, "status: ")
            printstyled(io, getstatus(job); bold=true)
            if !ispending(job)
                print(
                    io,
                    '\n',
                    ' '^5,
                    "from: ",
                    format(starttime(job), "dd-u-YYYY HH:MM:SS.s"),
                    '\n',
                    ' '^5,
                    "to: ",
                )
                if isrunning(job)
                    print(io, "still running...")
                else
                    println(io, format(stoptime(job), "dd-u-YYYY HH:MM:SS.s"))
                    print(io, ' '^5, "uses: ", elapsed(job))
                end
            end
            println(io)
        end
    end
end

include("run!.jl")
include("status.jl")
