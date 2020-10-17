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

export Workflow, eachjob, chain, backchain, parallel, ←, →, ∥

struct Workflow
    graph::DiGraph{Int}
    nodes::Tuple
    function Workflow(graph, nodes)
        @assert !is_cyclic(graph) "`graph` must be an acyclic graph!"
        if nv(graph) != length(nodes)
            throw(DimensionMismatch("`graph`'s size is different from `nodes`!"))
        end
        return new(graph, nodes)
    end
end
Workflow() = Workflow(DiGraph(), ())

struct TieInPoint
    workflow::Workflow
    index::UInt
end

Base.getindex(w::Workflow, i::Number) = TieInPoint(w, UInt(i))
Base.getindex(w::Workflow, I) = Workflow(w.graph[I], w.nodes[I])
Base.firstindex(w::Workflow) = 1
Base.lastindex(w::Workflow) = nv(w.graph)

chain(a::Job, b::Job) = Workflow(DiGraph(2, 1), (a, b))
function chain(a::Job, b::Job, c::Job, xs::Job...)  # See https://github.com/JuliaLang/julia/blob/be54a6c/base/operators.jl#L540
    n = length(xs)
    g = DiGraph(3 + n)
    map(i -> add_edge!(g, i, i + 1), 1:(2+n))
    return Workflow(g, (a, b, c, xs...))
end
function chain(wi::TieInPoint, j::Job)
    add_vertex!(wi.workflow.graph)
    add_edge!(wi.workflow.graph, wi.index, nv(wi.workflow.graph))
    return Workflow(wi.workflow.graph, push!!(wi.workflow.nodes, j))
end
function chain(j::Job, wi::TieInPoint)
    g = DiGraph(1)
    h = g ⊕ wi.workflow.graph
    add_edge!(h, 1, wi.index + 1)
    return Workflow(h, pushfirst!!(wi.workflow.nodes, j))
end
function chain(a::TieInPoint, b::TieInPoint)
    g = a.workflow.graph ⊕ b.workflow.graph
    add_edge!(g, a.index, b.index + nv(a.workflow.graph))
    return Workflow(g, append!!(a.workflow.nodes, b.workflow.nodes))
end

backchain(a::Union{Job,TieInPoint}, b::Union{Job,TieInPoint}) = chain(b, a)
backchain(c::Job, b::Job, a::Job, xs::Job...) = chain(xs..., a, b, c)

function parallel(a::Job, b::Job, xs::Job...)
    g = DiGraph(4 + length(xs))
    n = nv(g)
    for i in 2:(n-1)
        add_edge!(g, 1, i)
        add_edge!(g, i, n)
    end
    return Workflow(g, (EmptyJob(), a, b, xs..., EmptyJob()))
end
function parallel(w::TieInPoint, b::Job)
    @assert length(inneighbors(w.workflow.graph, w.index)) == 1
    p = inneighbors(w.workflow.graph, w.index)
    g = w.workflow.graph
    add_vertex!(g)
    add_edge!(g, only(p), nv(g))
    return Workflow(g, push!!(w.workflow.nodes, b))
end
parallel(j::Job, w::TieInPoint) = parallel(w, j)
function parallel(a::TieInPoint, b::TieInPoint)
    g = DiGraph(1) ⊕ a.workflow.graph ⊕ b.workflow.graph
    add_edge!(g, 1, a.index + 1)
    add_edge!(g, 1, b.index + 1 + nv(a.workflow.graph))
    return Workflow(g, (EmptyJob(), a.workflow.nodes..., b.workflow.nodes...))
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

eachjob(w::Workflow) = (w.nodes[i] for i in vertices(w.graph))

function run!(w::Workflow)
    g, n = w.graph, w.nodes
    for i in vertices(g)
        inn = inneighbors(g, i)
        if !isempty(inn)
            for j in inn
                if !isexited(n[j])
                    wait(n[j])
                end
            end
        end
        run!(n[i])
    end
    return w
end

function ⊕(g::AbstractGraph, b::AbstractGraph)
    a = copy(g)
    add_vertices!(a, nv(b))
    for e in edges(b)
        add_edge!(a, src(e) + nv(g), dst(e) + nv(g))
    end
    return a
end

function Base.show(io::IO, wf::Workflow)
    for node in wf.nodes
        println(io, node)
    end
end
