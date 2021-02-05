using LightGraphs:
    AbstractGraph,
    DiGraph,
    add_edge!,
    add_vertex!,
    add_vertices!,
    nv,
    is_cyclic,
    vertices,
    edges,
    inneighbors,
    src,
    dst
using BangBang: push!!, pushfirst!!, append!!
using MetaGraphs: MetaGraph, MetaDiGraph, has_prop, get_prop, props, set_prop!

export Workflow, eachjob, chain, backchain, parallel, reset!, ←, →, ∥

struct Workflow
    graph::MetaDiGraph{Int,Float64}
    function Workflow(graph = MetaDiGraph())
        @assert !is_cyclic(graph) "`graph` must be an acyclic graph!"
        # @assert all(has_prop(graph, v, :job) for v in vertices(graph)) "all nodes must have property `:job`!"
        return new(graph)
    end
end

const WORKFLOW_REGISTRY = IdDict()

struct TieInPoint
    workflow::Workflow
    index::UInt
end

Base.getindex(w::Workflow, i::Number) = TieInPoint(w, UInt(i))
Base.getindex(w::Workflow, I) = Workflow(w.graph[I])
Base.firstindex(w::Workflow) = 1
Base.lastindex(w::Workflow) = nv(w.graph)

function chain(a::Job, b::Job)
    g = MetaDiGraph(DiGraph(2, 1))
    set_prop!(g, 1, :job, a)
    set_prop!(g, 2, :job, b)
    return Workflow(g)
end
function chain(a::Job, b::Job, c::Job, xs::Job...)  # See https://github.com/JuliaLang/julia/blob/be54a6c/base/operators.jl#L540
    n = length(xs)
    g = DiGraph(3 + n)
    foreach(i -> add_edge!(g, i, i + 1), 1:(2+n))
    g = MetaDiGraph(g)
    for (i, job) in zip(1:(3+n), (a, b, c, xs...))
        set_prop!(g, i, :job, job)
    end
    return Workflow(g)
end
function chain(wi::TieInPoint, j::Job)
    add_vertex!(wi.workflow.graph)
    add_edge!(wi.workflow.graph, wi.index, nv(wi.workflow.graph))
    set_prop!(wi.workflow.graph, nv(wi.workflow.graph), :job, j)
    return Workflow(wi.workflow.graph)
end
function chain(j::Job, wi::TieInPoint)
    g = MetaDiGraph(DiGraph(1))
    h = g ⊕ wi.workflow.graph
    add_edge!(h, 1, wi.index + 1)
    set_prop!(h, 1, :job, j)
    return Workflow(h)
end
function chain(a::TieInPoint, b::TieInPoint)
    g = a.workflow.graph ⊕ b.workflow.graph
    add_edge!(g, a.index, b.index + nv(a.workflow.graph))
    return Workflow(g)
end

backchain(a::Union{Job,TieInPoint}, b::Union{Job,TieInPoint}) = chain(b, a)
backchain(c::Job, b::Job, a::Job, xs::Job...) = chain(xs..., a, b, c)

function parallel(a::Job, b::Job, xs::Job...)
    g = MetaDiGraph(DiGraph(4 + length(xs)))
    n = nv(g)
    for (i, job) in zip(2:(n-1), (a, b, xs...))
        add_edge!(g, 1, i)
        add_edge!(g, i, n)
        set_prop!(g, i, :job, job)
    end
    set_prop!(g, 1, :job, EmptyJob())
    set_prop!(g, n, :job, EmptyJob())
    return Workflow(g)
end
function parallel(w::TieInPoint, b::Job)
    @assert length(inneighbors(w.workflow.graph, w.index)) == 1
    p = inneighbors(w.workflow.graph, w.index)
    g = w.workflow.graph
    add_vertex!(g)
    add_edge!(g, only(p), nv(g))
    set_prop!(g, nv(g), :job, b)
    return Workflow(g)
end
parallel(j::Job, w::TieInPoint) = parallel(w, j)
function parallel(a::TieInPoint, b::TieInPoint)
    g = MetaDiGraph(DiGraph(1) ⊕ a.workflow.graph ⊕ b.workflow.graph)
    add_edge!(g, 1, a.index + 1)
    add_edge!(g, 1, b.index + 1 + nv(a.workflow.graph))
    set_prop!(g, 1, :job, EmptyJob())
    return Workflow(g)
end

for op in (:chain, :backchain, :parallel)
    @eval begin
        ($op)(a::TieInPoint, b::TieInPoint, c::TieInPoint, xs::TieInPoint...) =
            Base.afoldl(($op), a, b, c, xs...)
    end
end

const → = chain
const ← = backchain
const ∥ = parallel

eachjob(w::Workflow) = (get_prop(w.graph, i, :job) for i in vertices(w.graph))

function run!(w::Workflow)
    WORKFLOW_REGISTRY[w] = w
    g = w.graph
    for i in vertices(g)
        node = get_prop(g, i, :job)
        if !issucceeded(node)  # If not succeeded, prepare to run
            inn = inneighbors(g, i)
            if !isempty(inn)  # First, see if previous jobs were finished
                for j in inn
                    innode = get_prop(g, j, :job)
                    if !isexited(innode)
                        wait(innode)  # Wait until all previous jobs are finished
                        WORKFLOW_REGISTRY[w] = w
                    end
                end
            end
            run!(node)  # Finally, run the job
            WORKFLOW_REGISTRY[w] = w
        end
    end
    return w
end

function reset!(job::Job)
    if job isa ExternalAtomicJob
        return ExternalAtomicJob(job.cmd, job.desc)
    elseif job isa InternalAtomicJob
        return InternalAtomicJob(job.fun, job.desc)
    else  # EmptyJob
        return EmptyJob(job.desc)
    end
end
function reset!(w::Workflow)
    for i in w.graph
        set_prop!(w.graph, i, :job, reset!(get_prop(w.graph, i, :job)))
    end
    return w
end

function getstatus(w::Workflow)
    return map(getstatus, eachjob(w))
end

function description(w::Workflow)
    return map(description, eachjob(w))
end

function ⊕(g::MetaDiGraph, b::MetaDiGraph)
    a = copy(g)
    add_vertices!(a, nv(b))
    for i in 1:nv(b)
        set_prop!(a, i + nv(g), :job, get_prop(b, i, :job))
    end
    for e in edges(b)
        add_edge!(a, src(e) + nv(g), dst(e) + nv(g))
    end
    return a
end

function Base.show(io::IO, wf::Workflow)
    for node in eachjob(wf)
        println(io, node)
    end
end
