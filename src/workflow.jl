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
using JLD2: load, jldopen, jldsave

export Workflow, chain, thread, fork, converge, spindle, →, ←, ⇶, ⬱, ⇉, ⭃

"""
    Workflow(jobs, graph)

Create a `Workflow` from a list of `Job`s and a graph representing their relations.
"""
struct Workflow
    jobs::Vector{Job}
    graph::DiGraph{Int}
    function Workflow(jobs, graph)
        @assert !is_cyclic(graph) "`graph` must be acyclic"
        @assert is_connected(graph) "`graph` must be connected!"
        @assert nv(graph) == length(jobs) "`graph` has different size from `jobs`!"
        @assert allunique(jobs) "at least two jobs are identical!"
        return new(jobs, graph)
    end
end
"""
    Workflow(jobs::Job...)

Create a `Workflow` from a given series of `Job`s.

The list of `Job`s does not have to be complete, our algorithm will find all connected `Job`s
automatically.
"""
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

"""
    chain(x::Job, y::Job, z::Job...)

Chain multiple `Job`s one after another.
"""
function chain(x::Job, y::Job)
    if x == y
        throw(ArgumentError("a job cannot be followed by itself!"))
    else
        push!(x.children, y)
        push!(y.parents, x)
        return x
    end
end
chain(x::Job, y::Job, z::Job...) = foldr(chain, (x, y, z...))
"""
    →(x, y)

Chain two `Job`s.
"""
→(x::Job, y::Job) = chain(x, y)
"""
    ←(y, x)

Chain two `Job`s reversely.
"""
←(y::Job, x::Job) = x → y

"""
    thread(xs::AbstractVector{Job}, ys::AbstractVector{Job}, zs::AbstractVector{Job}...)

Chain multiple vectors of `Job`s, each `Job` in `xs` has a corresponding `Job` in `ys`.`
"""
function thread(xs::AbstractVector{Job}, ys::AbstractVector{Job})
    if size(xs) != size(ys)
        throw(DimensionMismatch("`xs` and `ys` must have the same size!"))
    end
    for (x, y) in zip(xs, ys)
        chain(x, y)
    end
    return xs
end
thread(xs::AbstractVector{Job}, ys::AbstractVector{Job}, zs::AbstractVector{Job}...) =
    foldr(thread, (xs, ys, zs...))
"""
    ⇶(xs, ys)

Chain two vectors of `Job`s.
"""
⇶(xs::AbstractVector{Job}, ys::AbstractVector{Job}) = thread(xs, ys)
"""
    ⬱(ys, xs)

Chain two vectors of `Job`s reversely.
"""
⬱(ys::AbstractVector{Job}, xs::AbstractVector{Job}) = xs ⇶ ys

"""
    fork(x::Job, ys::AbstractVector{Job})
    ⇉(x, ys)

Attach a group of parallel `Job`s (`ys`) to a single `Job` (`x`).
"""
function fork(x::Job, ys::AbstractVector{Job})
    for y in ys
        chain(x, y)
    end
    return x
end
const ⇉ = fork

"""
    converge(xs::AbstractVector{Job}, y::Job)
    ⭃(xs, y)

Finish a group a parallel `Job`s (`xs`) by a single `Job` (`y`).
"""
function converge(xs::AbstractVector{Job}, y::Job)
    for x in xs
        chain(x, y)
    end
    return xs
end
const ⭃ = converge

"""
    spindle(x::Job, ys::AbstractVector{Job}, z::Job)

Start from a `Job` (`x`), followed by a series of `Job`s (`ys`), finished by a single `Job` (`z`).
"""
spindle(x::Job, ys::AbstractVector{Job}, z::Job) = x ⇉ ys ⭃ z

"""
    run!(wf::Workflow; n=5, δt=1, Δt=1, filename="saved.jld2")

Run a `Workflow` with maximum `n` attempts, with each attempt separated by `Δt` seconds.

Cool down for `δt` seconds after each `Job` in the `Workflow`. Save the tracking information
to a file named `saved.jld2`.
"""
function run!(wf::Workflow; n = 5, δt = 1, Δt = 1, filename = "saved.jld2")
    @assert isinteger(n) && n >= 1
    if isfile(filename)
        saved = load(filename)
        if saved["jobs"] isa AbstractVector{Job} && saved["graph"] == wf.graph
            for (job, status) in zip(wf.jobs, saved["status"])
                job.status = status  # Inherit status from file
            end
        end
    else
        jldsave(filename; jobs = wf.jobs, graph = wf.graph, status = getstatus(wf))
    end
    for _ in 1:n
        if any(!issucceeded(job) for job in wf.jobs)
            _run!(wf; δt = δt, filename = filename)
        end
        if all(issucceeded(job) for job in wf.jobs)
            break  # Stop immediately
        end
        if !iszero(Δt)  # If still unsuccessful
            sleep(Δt)  # `if-else` is faster than `sleep(0)`
        end
    end
    return wf
end
function _run!(wf::Workflow; δt, filename)
    jobs, graph = copy(wf.jobs), copy(wf.graph)  # This separation is necessary, or else we call this every iteration of `__run!`
    __run!(wf, jobs, graph; δt = δt, filename = filename)
    return wf
end
function __run!(wf, jobs, graph; δt, filename)  # This will modify `wf`
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
                run!(job; n = 1, δt = δt)
                wait(job)
                jldopen(filename, "r+") do file
                    Base.delete!(file, "status")
                    write(file, "status", getstatus(wf))
                end
            end
        end
        rem_vertices!(graph, queue; keep_order = true)
        deleteat!(jobs, queue)
        return __run!(wf, jobs, graph; δt = δt, filename = filename)
    end
end

"""
    getstatus(wf::Workflow)

Get the current status of each `Job` in a `Workflow`.
"""
getstatus(wf::Workflow) = map(getstatus, wf.jobs)

function Base.show(io::IO, wf::Workflow)
    if get(io, :compact, false) || get(io, :typeinfo, nothing) == typeof(wf)
        Base.show_default(IOContext(io, :limit => true), wf)  # From https://github.com/mauro3/Parameters.jl/blob/ecbf8df/src/Parameters.jl#L556
    else
        println(io, summary(wf))
        println(io, ' ', wf.graph)
        println(io, "jobs:")
        for (i, job) in enumerate(wf.jobs)
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
                print(
                    io,
                    '\n',
                    ' '^5,
                    "from: ",
                    format(starttime(job), "dd-u-YYYY HH:MM:SS.s"),
                    '\n',
                    ' '^5,
                    "to: ",
                )
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
