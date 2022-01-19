using Graphs:
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
using Serialization: serialize, deserialize

export Workflow, dependencies, chain, lfork, rfork, diamond, ▷, ⋲, ⋺, ⋄

const DEPENDENCIES = Dict{Job,Vector{AtomicJob}}()

struct Workflow
    graph::DiGraph{Int}
    jobs::Vector{AtomicJob}
    function Workflow(graph, jobs)
        @assert !is_cyclic(graph) "`graph` must be an acyclic graph!"
        @assert is_connected(graph) "`graph` is not connected!"
        if nv(graph) != length(jobs)
            throw(DimensionMismatch("`graph`'s size is different from `jobs`!"))
        end
        @assert unique(jobs) == jobs "at least two jobs are identical!"
        return new(graph, jobs)
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

function run!(w::Workflow; nap_job = 3, attempts = 5, nap = 3, saveas = "status.jls")
    if isfile(saveas)
        saved = open(saveas, "r") do io
            deserialize(io)
        end
        if saved isa Workflow && saved.graph == w.graph
            w = saved
        end
    end
    @assert isinteger(attempts) && attempts >= 1
    for _ in 1:attempts
        inner_run!(w; nap_job = nap_job, saveas = saveas)
        if any(!issucceeded(job) for job in w.jobs)
            inner_run!(w; nap_job = nap_job, saveas = saveas)
            all(issucceeded(job) for job in w.jobs) ? break : sleep(nap)
        end
    end
    return w
end
function inner_run!(w::Workflow; nap_job, saveas)
    for job in w.jobs  # The nodes have been topologically sorted.
        if !issucceeded(job)
            if !isrunning(job)  # Run the job if it is not already running
                run!(job; attempts = 1)
            end
            wait(job)
            open(saveas, "w") do io
                serialize(io, w)
            end
            sleep(nap_job)
        end
    end
    return w
end

function initialize!()
    empty!(DEPENDENCIES)
    empty!(JOB_REGISTRY)
    return
end
function initialize!(w::Workflow)
    for node in w.jobs
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
        for (i, job) in enumerate(w.jobs)
            println(io, " (", i, ") ", "id: ", job.id)
            if !isempty(job.desc)
                print(io, ' '^5, "description: ")
                show(io, job.desc)
                println(io)
            end
            print(io, ' '^5, "def: ")
            show(io, job.def)
            print(io, '\n', ' '^5, "status: ")
            printstyled(io, getstatus(job); bold = true)
            if !ispending(job)
                println(
                    io,
                    '\n',
                    ' '^5,
                    "from: ",
                    format(starttime(job), "dd-u-YYYY HH:MM:SS.s"),
                )
                print(io, ' '^5, "to: ")
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
