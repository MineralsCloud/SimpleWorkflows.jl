using LightGraphs:
    AbstractGraph,
    DiGraph,
    add_edge!,
    add_vertices!,
    nv,
    is_cyclic,
    edges,
    topological_sort_by_dfs,
    src,
    dst

export Workflow, dependencies, →

const DEPENDENCIES = Dict{Job,Vector{AtomicJob}}()

struct Workflow
    graph::DiGraph{Int}
    nodes::Vector{AtomicJob}
    function Workflow(graph, nodes)
        @assert !is_cyclic(graph) "`graph` must be an acyclic graph!"
        if nv(graph) != length(nodes)
            throw(DimensionMismatch("`graph`'s size is different from `nodes`!"))
        end
        @assert unique(nodes) == nodes "at least two jobs are identical!"
        return new(graph, nodes)
    end
end
function Workflow(jobs::Job...)
    graph = DiGraph(length(jobs))
    dict = Dict(zip(jobs, 1:length(jobs)))
    for (i, job) in enumerate(jobs)
        for dependency in dependencies(job)
            j = dict[dependency]
            add_edge!(graph, j, i)
        end
    end
    order = topological_sort_by_dfs(graph)
    new = collect(jobs[order])
    graph = DiGraph(length(jobs))
    dict = Dict(zip(jobs, 1:length(jobs)))
    for (i, job) in enumerate(jobs)
        for dependency in dependencies(job)
            j = dict[dependency]
            add_edge!(graph, j, i)
        end
    end
    return Workflow(graph, new)
end

dependencies(job::Job) = get(DEPENDENCIES, job, AtomicJob[])

# See https://discourse.julialang.org/t/how-to-define-an-infix-operator-that-can-act-on-multiple-arguments-at-once-like/64954/4
struct AndJobs
    a::Job
    b::Job
end

function →(a::Job, b::Job)
    if a == b
        throw(ArgumentError("a job cannot have itself as a dependency!"))
    else
        if haskey(DEPENDENCIES, b)
            if a ∉ DEPENDENCIES[b]  # Duplicate running will push the same job multiple times
                push!(DEPENDENCIES[b], a)
            end
        else
            push!(DEPENDENCIES, b => [a])  # Initialization
        end
        return AndJobs(a, b)
    end
end
→(x::AndJobs, y::Job) = x.b → y
→(x::Job, y::AndJobs) = x → y.a

function ⊕(g::AbstractGraph, b::AbstractGraph)
    a = copy(g)
    add_vertices!(a, nv(b))
    for e in edges(b)
        add_edge!(a, src(e) + nv(g), dst(e) + nv(g))
    end
    return a
end

function run!(w::Workflow)
    for job in w.nodes  # The nodes have been topologically sorted.
        if !issucceeded(job)
            if isrunning(job)
                wait(job)
            else
                run!(job)
            end
        end
    end
    return Workflow
end
