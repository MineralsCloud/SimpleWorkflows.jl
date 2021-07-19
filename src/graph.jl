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
using MetaGraphs: MetaGraph, set_prop!


const DEPENDENCIES = Dict{Job,Vector{AtomicJob}}()

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
