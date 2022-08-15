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
using JLD2: load, jldsave

export Workflow,
    chain,
    thread,
    fork,
    converge,
    spindle,
    pendingjobs,
    runningjobs,
    exitedjobs,
    failedjobs,
    interruptedjobs,
    →,
    ←,
    ⇶,
    ⬱,
    ⇉,
    ⭃

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

struct SavedWorkflow{T}
    wf::Workflow
    file::T
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
function run!(wf::Union{Workflow,SavedWorkflow}; n = 5, δt = 1, Δt = 1)
    @assert isinteger(n) && n >= 1
    save(wf)
    for _ in 1:n
        if any(!issucceeded(job) for job in wf.jobs)
            run_copy!(wf; δt = δt)
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
function run_copy!(wf; δt)  # Do not export!
    jobs, graph = copy(wf.jobs), copy(wf.graph)  # This separation is necessary, or else we call this every iteration of `run_kahn_algo!`
    run_kahn_algo!(wf, jobs, graph; δt = δt)
    return wf
end
function run_kahn_algo!(wf, jobs, graph; δt)  # Do not export!
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
                save(wf)
            end
        end
        rem_vertices!(graph, queue; keep_order = true)
        deleteat!(jobs, queue)
        return run_kahn_algo!(wf, jobs, graph; δt = δt)
    end
end

"""
    getstatus(wf::Workflow)

Get the current status of each `Job` in a `Workflow`.
"""
getstatus(wf::Workflow) = map(getstatus, wf.jobs)

pendingjobs(jobs) = filter(ispending, jobs)
pendingjobs(wf::Workflow) = pendingjobs(wf.jobs)

runningjobs(jobs) = filter(isrunning, jobs)
runningjobs(wf::Workflow) = runningjobs(wf.jobs)

exitedjobs(jobs) = filter(isexited, jobs)
exitedjobs(wf::Workflow) = exitedjobs(wf.jobs)

succeededjobs(jobs) = filter(issucceeded, jobs)
succeededjobs(wf::Workflow) = succeededjobs(wf.jobs)

failedjobs(jobs) = filter(isfailed, jobs)
failedjobs(wf::Workflow) = failedjobs(wf.jobs)

interruptedjobs(jobs) = filter(isinterrupted, jobs)
interruptedjobs(wf::Workflow) = interruptedjobs(wf.jobs)

save(::Workflow) = nothing
save(wf::SavedWorkflow) = jldsave(wf.file; workflow = wf.wf)

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
            printfunc(io, job.thunk)
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
