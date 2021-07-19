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

function →(a::Job, b::Job)
    if a == b
        throw(ArgumentError("a job cannot have itself as a dependency!"))
    else
        if haskey(DEPENDENCIES, b)
            push!(DEPENDENCIES[b], a)
        else
            push!(DEPENDENCIES, b => [a])  # Initialization
        end
        return
    end
end
function →(a::Job, b::Job, c::Job, xs::Job...)  # See https://github.com/JuliaLang/julia/blob/be54a6c/base/operators.jl#L540
    foreach(zip((a, b, xs[1:end-1]...), (b, c, xs...))) do x, y
        x → y
    end
end

function ⊕(g::AbstractGraph, b::AbstractGraph)
    a = copy(g)
    add_vertices!(a, nv(b))
    for e in edges(b)
        add_edge!(a, src(e) + nv(g), dst(e) + nv(g))
    end
    return a
end
