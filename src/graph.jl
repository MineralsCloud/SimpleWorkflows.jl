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

export Workflow, chain, lfork, rfork, diamond, ▷, ⋲, ⋺, ⋄

const DEPENDENCIES = Dict{Job,Vector{Job}}()

struct Node
    job::Job
    incoming::Vector{Node}
    outgoing::Vector{Node}
end
Node(job) = Node(job, Node[], Node[])

struct Workflow
    nodes::Vector{Node}
    graph::DiGraph{Int}
    function Workflow(nodes, graph)
        @assert !is_cyclic(graph) "`graph` must be acyclic"
        @assert is_connected(graph) "`graph` must be connected!"
        @assert nv(graph) == length(nodes) "`graph` has different size from `nodes`!"
        jobs = (node.job for node in nodes)
        @assert length(jobs) == length(unique(jobs)) "at least two jobs are identical!"
        return new(nodes, graph)
    end
end
function Workflow(nodes::Node...)
    graph = DiGraph(length(nodes))
    for (i, node) in enumerate(nodes)
        for j in node.outgoing
            add_edge!(graph, i, j)
        end
    end
    return Workflow(nodes, graph)
end

function chain(x::Job, y::Job)
    if x == y
        throw(ArgumentError("a job cannot be followed by itself!"))
    else
        a, b = Node(x), Node(y)
        push!(a.outgoing, b)
        return b
    end
end
function chain(xs::AbstractVector{<:Job}, ys::AbstractVector{<:Job})
    if size(xs) != size(ys)
        throw(DimensionMismatch("`xs` and `ys` must have the same size!"))
    end
    for (x, y) in zip(xs, ys)
        chain(x, y)
    end
    return ys
end
const ▷ = chain

function lfork(x::Job, ys::AbstractVector{<:Job})
    for y in ys
        chain(x, y)
    end
    return ys
end
const ⋲ = lfork

function rfork(xs::AbstractVector{<:Job}, y::Job)
    for x in xs
        x ▷ y
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
    for job in w.nodes  # The nodes have been topologically sorted.
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
