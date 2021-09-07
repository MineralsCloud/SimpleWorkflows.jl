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

export Workflow, dependencies, chain, lfork, rfork, diamond, ▷, ⋲, ⋺, ⋄

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

function chain(a::Job, b::Job)
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
        return b
    end
end
function chain(xs::AbstractVector{<:Job}, ys::AbstractVector{<:Job})
    for (x, y) in zip(xs, ys)
        x ▷ y
    end
    return ys
end
const ▷ = chain

function lfork(x::Job, ys::AbstractVector{<:Job})
    if x in ys
        throw(ArgumentError("a job cannot have itself as a dependency!"))
    else
        for y in ys
            x ▷ y
        end
    end
    return ys
end
const ⋲ = lfork

function rfork(xs::AbstractVector{<:Job}, y::Job)
    if y in xs
        throw(ArgumentError("a job cannot have itself as a dependency!"))
    else
        for x in xs
            x ▷ y
        end
    end
    return y
end
const ⋺ = rfork

diamond(x::Job, ys::AbstractVector{<:Job}, z::Job) = (x ⋲ ys) ⋺ z
const ⋄ = diamond

function run!(w::Workflow; sleep_job = 3, attempts = 5, sleep_attempt = 3)
    @assert isinteger(attempts) && attempts >= 1
    if attempts > 1
        w = run!(w; sleep_job = sleep_job, attempts = 1)
        if any(!issucceeded, w.nodes)
            sleep(sleep_attempt)
            return run!(
                w;
                sleep_job = sleep_job,
                attempts = attempts - 1,
                sleep_attempt = sleep_attempt,
            )
        else
            return w
        end
    else  # attempts == 1
        @sync for job in w.nodes  # The nodes have been topologically sorted.
            @async if !issucceeded(job)
                if isrunning(job)
                    wait(job)
                    sleep(sleep_job)
                else
                    run!(job)
                    wait(job)
                    sleep(sleep_job)
                end
            end
        end
        return Workflow
    end
end

function initialize!()
    empty!(DEPENDENCIES)
    empty!(JOB_REGISTRY)
    return
end
function initialize!(w::Workflow)
    for node in w.nodes
        initialize!(node)
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
