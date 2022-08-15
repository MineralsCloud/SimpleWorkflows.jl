using DataFrames: DataFrame, sort, filter
using Dates: DateTime, Period, Day, now, format
using TryCatch: @try
using UUIDs: UUID, uuid1

using .Thunks: Thunk, reify!, printfunc

import .Thunks: getresult

export Job
export getstatus,
    getresult,
    description,
    ispending,
    isrunning,
    isexited,
    issucceeded,
    isfailed,
    isinterrupted,
    createdtime,
    starttime,
    stoptime,
    elapsed,
    run!,
    interrupt!,
    queue,
    query,
    isexecuted,
    ntimes

@enum JobStatus begin
    PENDING
    RUNNING
    SUCCEEDED
    FAILED
    INTERRUPTED
end

# Reference: https://github.com/cihga39871/JobSchedulers.jl/blob/aca52de/src/jobs.jl#L35-L69
"""
    Job(def; desc="", user="")

Create a simple job.

# Arguments
- `def`: A closure that encloses the job definition.
- `desc::String=""`: Describe briefly what this job does.
- `user::String=""`: Indicate who executes this job.

# Examples
```@repl
a = Job(() -> sleep(5); user="me", desc="Sleep for 5 seconds")
b = Job(() -> run(`pwd` & `ls`); user="me", desc="Run some commands")
```
"""
mutable struct Job
    id::UUID
    thunk::Thunk
    desc::String
    user::String
    created_time::DateTime
    start_time::DateTime
    stop_time::DateTime
    "Track the job status."
    status::JobStatus
    count::UInt64
    "These jobs runs before the current job."
    parents::Vector{Job}
    "These jobs runs after the current job."
    children::Vector{Job}
    Job(thunk; desc = "", user = "") = new(
        uuid1(),
        thunk,
        desc,
        user,
        now(),
        DateTime(0),
        DateTime(0),
        PENDING,
        nothing,
        0,
        [],
        [],
    )
end
"""
    Job(job::Job)

Create a new `Job` from an existing `Job`.
"""
Job(job::Job) = Job(
    job.thunk;
    desc = job.desc,
    user = job.user,
    parents = job.parents,
    children = job.children,
)

const JOB_REGISTRY = Dict{Job,Union{Nothing,Task}}()

function initialize!()
    empty!(JOB_REGISTRY)
    return
end

"""
    run!(job::Job; n=1, δt=1)

Run a `Job` with maximum `n` attempts, with each attempt separated by `δt` seconds.
"""
function run!(job::Job; n = 1, δt = 1)
    @assert isinteger(n) && n >= 1
    for _ in 1:n
        if !issucceeded(job)
            _run!(job)
        end
        if issucceeded(job)
            break  # Stop immediately
        end
        if !iszero(δt)  # Still unsuccessful
            sleep(δt)  # `if-else` is faster than `sleep(0)`
        end
    end
    return job
end
function _run!(job::Job)
    if ispending(job)
        if !isexecuted(job)
            push!(JOB_REGISTRY, job => nothing)
        end
        JOB_REGISTRY[job] = @async __run!(job)
    else
        job.status = PENDING
        return _run!(job)
    end
end
function __run!(job::Job)
    job.status = RUNNING
    job.start_time = now()
    reify!(job.thunk)
    job.stop_time = now()
    result = getresult(job.thunk)
    if result isa ErrorException
        job.status = result isa InterruptException ? INTERRUPTED : FAILED
    else
        job.status = SUCCEEDED
    end
    job.count += 1
    return job
end

"""
    queue(; sortby = :created_time)

Print all `Job`s that are pending, running, or finished as a table.

Accpetable arguments for `sortby` are `:created_time`, `:user`, `:start_time`, `:stop_time`,
`:elapsed`, `:status`, and `:times`.
"""
function queue(; sortby = :created_time)
    @assert sortby in
            (:created_time, :user, :start_time, :stop_time, :elapsed, :status, :times)
    jobs = collect(keys(JOB_REGISTRY))
    df = DataFrame(
        id = [job.id for job in jobs],
        user = [job.user for job in jobs],
        created_time = map(createdtime, jobs),
        start_time = map(starttime, jobs),
        stop_time = map(stoptime, jobs),
        elapsed = map(elapsed, jobs),
        status = map(getstatus, jobs),
        times = map(ntimes, jobs),
        desc = map(description, jobs),
    )
    return sort(df, [:id, sortby])
end

"""
    query(id::Integer)
    query(ids::AbstractVector{<:Integer})

Query a specific (or a list of `Job`s) by its (theirs) ID.
"""
query(id::Integer) = filter(row -> row.id == id, queue())
query(ids::AbstractVector{<:Integer}) = map(id -> query(id), ids)

isexecuted(job::Job) = job in keys(JOB_REGISTRY)

"""
    ntimes(id::Integer)
    ntimes(job::Job)

Return how many times a `Job` has been rerun.
"""
ntimes(id::Integer) = ntimes(first(filter(x -> x.id == id, JOB_REGISTRY)))
ntimes(job::Job) = Int(job.count)

"""
    getstatus(x::Job)

Get the current status of a `Job`.
"""
getstatus(job::Job) = job.status

"Test if the `Job` is still pending."
ispending(job::Job) = getstatus(job) === PENDING

"Test if the `Job` is running."
isrunning(job::Job) = getstatus(job) === RUNNING

"Test if the `Job` has exited."
isexited(job::Job) = getstatus(job) in (SUCCEEDED, FAILED, INTERRUPTED)

"Test if the `Job` was successfully run."
issucceeded(job::Job) = getstatus(job) === SUCCEEDED

"Test if the `Job` failed during running."
isfailed(job::Job) = getstatus(job) === FAILED

"Test if the `Job` was interrupted during running."
isinterrupted(job::Job) = getstatus(job) === INTERRUPTED

"Return the created time of a `Job`."
createdtime(job::Job) = job.created_time

"""
    starttime(job::Job)

Return the start time of a `Job`. Return `nothing` if it is still pending.
"""
starttime(job::Job) = ispending(job) ? nothing : job.start_time

"""
    stoptime(job::Job)

Return the stop time of a `Job`. Return `nothing` if it has not exited.
"""
stoptime(job::Job) = isexited(job) ? job.stop_time : nothing

"""
    elapsed(job::Job)

Return the elapsed time of a `Job` since it started running.

If `nothing`, the `Job` is still pending. If it is finished, return how long it took to
complete.
"""
function elapsed(job::Job)
    if ispending(job)
        return
    elseif isrunning(job)
        return now() - job.start_time
    else  # Exited
        return job.stop_time - job.start_time
    end
end

"""
    getresult(job::Job)

Get the running result of a `Job`.

The result is wrapped by a `Some` type. Use `something` to retrieve its value.
If it is `nothing`, the `Job` is not finished.
"""
getresult(job::Job) = isexited(job) ? Some(job.thunk.result) : nothing

"""
    description(job::Job)

Return the description of a `Job`.
"""
description(job::Job) = job.desc

"""
    interrupt!(job::Job)

Manually interrupt a `Job`, works only if it is running.
"""
function interrupt!(job::Job)
    if isexited(job)
        @info "the job $(job.id) has already exited!"
    elseif ispending(job)
        @info "the job $(job.id) has not started!"
    else
        schedule(JOB_REGISTRY[job], InterruptException(); error = true)
    end
    return job
end

Base.wait(job::Job) = wait(JOB_REGISTRY[job])

function Base.show(io::IO, job::Job)
    if get(io, :compact, false) || get(io, :typeinfo, nothing) == typeof(job)
        Base.show_default(IOContext(io, :limit => true), job)  # From https://github.com/mauro3/Parameters.jl/blob/ecbf8df/src/Parameters.jl#L556
    else
        println(io, summary(job))
        println(io, ' ', "id: ", job.id)
        if !isempty(job.desc)
            print(io, ' ', "description: ")
            show(io, job.desc)
            println(io)
        end
        print(io, ' ', "def: ")
        printfunc(io, job.thunk)
        print(io, '\n', ' ', "status: ")
        printstyled(io, getstatus(job); bold = true)
        if !ispending(job)
            println(io, '\n', ' ', "from: ", format(starttime(job), "dd-u-YYYY HH:MM:SS.s"))
            print(io, ' ', "to: ")
            if isrunning(job)
                print(io, "still running...")
            else
                println(io, format(stoptime(job), "dd-u-YYYY HH:MM:SS.s"))
                print(io, ' ', "uses: ", elapsed(job))
            end
        end
    end
end
