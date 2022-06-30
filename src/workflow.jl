using Graphs:
    DiGraph,
    add_edge!,
    nv,
    is_cyclic,
    is_connected,
    has_edge,
    topological_sort_by_dfs,
    indegree,
    rem_vertices!
using Serialization: serialize, deserialize

export Workflow, chain, fork, converge, diamond, ▷, ⋲, ⋺, ⋄

struct Workflow
    jobs::Vector{Job}
    graph::DiGraph{Int}
    function Workflow(jobs, graph)
        @assert !is_cyclic(graph) "`graph` must be acyclic"
        @assert is_connected(graph) "`graph` must be connected!"
        @assert nv(graph) == length(jobs) "`graph` has different size from `jobs`!"
        @assert length(jobs) == length(unique(jobs)) "at least two jobs are identical!"
        return new(jobs, graph)
    end
end
function Workflow(jobs::Job...)
    all_possible_jobs = collect(jobs)
    for job in all_possible_jobs
        neighbors = vcat(job.parents, job.children)
        for neighbor in neighbors
            if neighbor ∉ all_possible_jobs
                push!(all_possible_jobs, neighbor)  # This will alter `all_possible_jobs` dynamically
            end
        end
    end
    n = length(all_possible_jobs)
    graph = DiGraph(n)
    dict = IdDict(zip(all_possible_jobs, 1:n))
    for (i, job) in enumerate(all_possible_jobs)
        for parent in job.parents
            if !has_edge(graph, dict[parent], i)
                add_edge!(graph, dict[parent], i)
            end
        end
        for child in job.children
            if !has_edge(graph, i, dict[child])
                add_edge!(graph, i, dict[child])
            end
        end
    end
    return Workflow(all_possible_jobs, graph)
end

function chain(x::Job, y::Job)
    if x == y
        throw(ArgumentError("a job cannot be followed by itself!"))
    else
        push!(x.children, y)
        push!(y.parents, x)
        return y
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

function fork(x::Job, ys::AbstractVector{<:Job})
    for y in ys
        chain(x, y)
    end
    return ys
end
const ⋲ = fork

function converge(xs::AbstractVector{<:Job}, y::Job)
    for x in xs
        chain(x, y)
    end
    return y
end
const ⋺ = converge

diamond(x::Job, ys::AbstractVector{<:Job}, z::Job) = converge(fork(x, ys), z)
const ⋄ = diamond

function run!(w::Workflow; nap_job = 3, attempts = 5, nap = 3, saveas = "status.jls")
    @assert isinteger(attempts) && attempts >= 1
    if isfile(saveas)
        saved = open(saveas, "r") do io
            deserialize(io)
        end
        if saved isa Workflow && saved.graph == w.graph
            w = saved
        end
    end
    for _ in 1:attempts
        _run!(w; nap_job = nap_job, saveas = saveas)
        if any(!issucceeded(job) for job in w.jobs)
            _run!(w; nap_job = nap_job, saveas = saveas)
            all(issucceeded(job) for job in w.jobs) ? break : sleep(nap)
        end
    end
    return w
end
function _run!(wf::Workflow; nap_job, saveas)
    jobs, graph = copy(wf.jobs), copy(wf.graph)  # This separation is necessary, or else we call this every iteration of `core_run!`
    __run!(jobs, graph; nap_job, saveas)
    return wf
end
function __run!(jobs, graph; nap_job, saveas)  # This will modify `wf`
    if isempty(jobs) && iszero(nv(graph))  # Stopping criterion
        return
    elseif isempty(jobs) && !iszero(nv(graph)) || !isempty(jobs) && iszero(nv(graph))
        throw(
            ArgumentError(
                "either `jobs` is empty but `graph` is not, or `graph` is empty but `jobs` is not!",
            ),
        )
    else
        queue = findall(iszero, indegree(graph))
        @sync for job in jobs[queue]
            @async begin
                run!(job; attempts = 1)
                open(saveas, "w") do io
                    serialize(io, wf)
                end
                sleep(nap_job)
            end
        end
        rem_vertices!(graph, queue; keep_order = true)
        deleteat!(jobs, queue)
        return __run!(jobs, graph; nap_job, saveas)
    end
end

function initialize!()
    empty!(JOB_REGISTRY)
    return
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
