using LightGraphs:
    AbstractGraph,
    DiGraph,
    add_edge!,
    add_vertices!,
    nv,
    is_cyclic,
    is_connected,
    edges,
    topological_sort_by_dfs,
    src,
    dst

export Workflow, dependencies, →, ⋲, ⋺, ⋄

const DEPENDENCIES = Dict{Job,Vector{AtomicJob}}()

struct Workflow
    graph::DiGraph{Int}
    nodes::Vector{AtomicJob}
    function Workflow(graph, nodes)
        @assert !is_cyclic(graph) "`graph` must be an acyclic graph!"
        @assert is_connected(graph) "`graph` is not connected! some nodes are not used!"
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

function ⋲(x::Job, ys::Job...)
    if x in ys
        throw(ArgumentError("a job cannot have itself as a dependency!"))
    else
        for y in ys
            x → y
        end
    end
end

function ⋺(xs::Job...)
    @assert length(xs) >= 2
    y = last(xs)
    for x in xs[1:end-1]
        x → y
    end
end

function ⋄(xs::Job...)
    @assert length(xs) >= 3
    ⋲(first(xs), xs[2:end-1]...)
    ⋺(xs[2:end]...)
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

function reset!()
    empty!(DEPENDENCIES)
    empty!(JOB_REGISTRY)
    return
end
function reset!(w::Workflow)
    for node in w.nodes
        reset!(node)
    end
    return w
end

function Base.show(io::IO, w::Workflow)
    if get(io, :compact, false) || get(io, :typeinfo, nothing) == typeof(w)
        Base.show_default(IOContext(io, :limit => true), w)  # From https://github.com/mauro3/Parameters.jl/blob/ecbf8df/src/Parameters.jl#L556
    else
        println(io, summary(w))
        println(io, " ", w.graph)
        println(io, "jobs:")
        for (i, job) in enumerate(w.nodes)
            println(io, " ", i, "] ", "id: ", job.id)
            println(io, "    def: ", job.def)
        end
    end
end
