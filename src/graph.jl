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

import ...run!

export Workflow, eachjob, ←, →, ∥

struct Workflow
    graph::DiGraph
    nodes::Tuple
    function Workflow(graph, nodes)
        @assert !is_cyclic(graph) "`graph` is not an acyclic graph!"
        @assert nv(graph) == length(nodes)
        return new(graph, nodes)
    end
end

struct WorkflowIndex
    wf::Workflow
    i::UInt
end

Base.getindex(w::Workflow, i::Integer) = WorkflowIndex(w, UInt(i))
Base.firstindex(w::Workflow) = 1
Base.lastindex(w::Workflow) = nv(w.graph)

←(a::Union{Job,WorkflowIndex}, b::Union{Job,WorkflowIndex}) = →(b, a)
function →(a::Job, b::Job)
    return Workflow(DiGraph(2, 1), (a, b))
end
function →(wi::WorkflowIndex, j::Job)
    add_vertex!(wi.wf.graph)
    add_edge!(wi.wf.graph, wi.i, nv(wi.wf.graph))
    return Workflow(wi.wf.graph, push!!(wi.wf.nodes, j))
end
function →(j::Job, wi::WorkflowIndex)
    g = DiGraph(1)
    h = g ⊕ wi.wf.graph
    add_edge!(h, 1, wi.i + 1)
    return Workflow(h, pushfirst!!(wi.wf.nodes, j))
end
function →(a::WorkflowIndex, b::WorkflowIndex)
    g = a.wf.graph ⊕ b.wf.graph
    add_edge!(g, a.i, b.i + nv(a.wf.graph))
    return Workflow(g, append!!(a.wf.nodes, b.wf.nodes))
end

function ∥(a::Job, b::Job...)
    g = DiGraph(3 + length(b))
    n = nv(g)
    for i in 2:(n-1)
        add_edge!(g, 1, i)
        add_edge!(g, i, n)
    end
    return Workflow(g, (EmptyJob(), a, b..., EmptyJob()))
end
function ∥(w::WorkflowIndex, b::Job)
    @assert length(inneighbors(w.wf.graph, w.i)) == 1
    p = inneighbors(w.wf.graph, w.i)
    g = w.wf.graph
    add_vertex!(g)
    add_edge!(g, only(p), nv(g))
    return Workflow(g, push!!(w.wf.nodes, b))
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
