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

export Workflow, eachjob, ←, →, ∥

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

struct TieInPoint
    workflow::Workflow
    index::UInt
end

Base.getindex(w::Workflow, i::Integer) = TieInPoint(w, UInt(i))
Base.firstindex(w::Workflow) = 1
Base.lastindex(w::Workflow) = nv(w.graph)

→(a::Job, b::Job) = Workflow(DiGraph(2, 1), (a, b))
function →(a::Job, b::Job, c::Job, xs::Job...)  # See https://github.com/JuliaLang/julia/blob/be54a6c/base/operators.jl#L540
    n = length(xs)
    g = DiGraph(3 + n)
    map(i -> add_edge!(g, i, i + 1), 1:(2+n))
    return Workflow(g, (a, b, c, xs...))
end
function →(wi::TieInPoint, j::Job)
    add_vertex!(wi.workflow.graph)
    add_edge!(wi.workflow.graph, wi.index, nv(wi.workflow.graph))
    return Workflow(wi.workflow.graph, push!!(wi.workflow.nodes, j))
end
function →(j::Job, wi::TieInPoint)
    g = DiGraph(1)
    h = g ⊕ wi.workflow.graph
    add_edge!(h, 1, wi.index + 1)
    return Workflow(h, pushfirst!!(wi.workflow.nodes, j))
end
function →(a::TieInPoint, b::TieInPoint)
    g = a.workflow.graph ⊕ b.workflow.graph
    add_edge!(g, a.index, b.index + nv(a.workflow.graph))
    return Workflow(g, append!!(a.workflow.nodes, b.workflow.nodes))
end

←(a::Union{Job,TieInPoint}, b::Union{Job,TieInPoint}) = →(b, a)
←(c::Job, b::Job, a::Job, xs::Job...) = →(xs..., a, b, c)

function ∥(a::Job, b::Job, xs::Job...)
    g = DiGraph(4 + length(xs))
    n = nv(g)
    for i in 2:(n-1)
        add_edge!(g, 1, i)
        add_edge!(g, i, n)
    end
    return Workflow(g, (EmptyJob(), a, b, xs..., EmptyJob()))
end
function ∥(w::TieInPoint, b::Job)
    @assert length(inneighbors(w.workflow.graph, w.index)) == 1
    p = inneighbors(w.workflow.graph, w.index)
    g = w.workflow.graph
    add_vertex!(g)
    add_edge!(g, only(p), nv(g))
    return Workflow(g, push!!(w.workflow.nodes, b))
end
∥(j::Job, w::TieInPoint) = ∥(w, j)
function ∥(a::TieInPoint, b::TieInPoint)
    g = DiGraph(1) ⊕ a.workflow.graph ⊕ b.workflow.graph
    add_edge!(g, 1, a.index + 1)
    add_edge!(g, 1, b.index + 1 + nv(a.workflow.graph))
    return Workflow(g, (EmptyJob(), a.workflow.nodes..., b.workflow.nodes...))
end

for op in (:→, :←, :∥)
    @eval begin
        ($op)(a::TieInPoint, b::TieInPoint, c::TieInPoint, xs::TieInPoint...) =
            Base.afoldl(($op), a, b, c, xs...)
    end
end

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
