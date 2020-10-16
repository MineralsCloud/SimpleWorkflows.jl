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

export Workflow, eachjob, ∥


struct Workflow{T}
    graph::DiGraph
    nodes::T
end

struct WorkflowIndex
    wf::Workflow
    i::Integer
end

Base.getindex(w::Workflow, i::Integer) = WorkflowIndex(w, i)
Base.firstindex(w::Workflow) = 1
Base.lastindex(w::Workflow) = nv(w.graph)

function Base.:|>(a::Job, b::Job)
    g = DiGraph(2, 1)
    return Workflow(g, (a, b))
end
function Base.:|>(wi::WorkflowIndex, j::Job)
    add_vertex!(wi.wf.graph)
    add_edge!(wi.wf.graph, wi.i, nv(wi.wf.graph))
    return Workflow(wi.wf.graph, push!!(wi.wf.nodes, j))
end
function Base.:|>(j::Job, wi::WorkflowIndex)
    g = DiGraph(1)
    h = g ⊕ wi.wf.graph
    add_edge!(h, 1, wi.i + 1)
    return Workflow(h, pushfirst!!(wi.wf.nodes, j))
end
function Base.:|>(a::WorkflowIndex, b::WorkflowIndex)
    g = a.wf.graph ⊕ b.wf.graph
    add_edge!(g, a.i, b.i + nv(a.wf.graph))
    return Workflow(g, append!!(a.wf.nodes, b.wf.nodes))
end

function ∥(a::Job, b::Job)
    g = DiGraph(4)
    add_edge!(g, 1, 2)
    add_edge!(g, 1, 3)
    add_edge!(g, 2, 4)
    add_edge!(g, 3, 4)
    return Workflow(g, (EmptyJob(), a, b, EmptyJob()))
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
