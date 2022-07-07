using DataFrames: DataFrame, sort, filter
using Dates: DateTime, Period, Day, now, format
using TryCatch: @try

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
export @job

@enum JobStatus begin
    PENDING
    RUNNING
    SUCCEEDED
    FAILED
    INTERRUPTED
end

# Reference: https://github.com/cihga39871/JobSchedulers.jl/blob/aca52de/src/jobs.jl#L35-L69
"""
    Job(def; desc="", user="", max_time=Day(1), parents=Job[], children=Job[])

Create a simple job.

# Arguments
- `def`: A closure that encloses the job definition.
- `desc::String=""`: Describe briefly what this job does.
- `user::String=""`: Indicate who executes this job.
- `max_time::Dates.Period=Day(1)`: Set the maximum execution time of the job.
- `parents::Vector{Job}=[]`: These jobs runs before the current job.
- `children::Vector{Job}=[]`: These jobs runs after the current job.

# Examples
```@repl
a = Job(() -> sleep(5); user="me", desc="Sleep for 5 seconds", children=[b])
b = Job(() -> run(`pwd` & `ls`); user="me", desc="Run some commands", parents=[a])
```
"""
mutable struct Job
    id::Int64
    def::Function
    desc::String
    user::String
    created_time::DateTime
    start_time::DateTime
    stop_time::DateTime
    max_time::Period
    status::JobStatus
    ref::Union{Task,Nothing}
    count::UInt64
    parents::Vector{Job}
    children::Vector{Job}
    Job(def; desc = "", user = "", max_time = Day(1)) = new(
        generate_id(),
        def,
        desc,
        user,
        now(),
        DateTime(0),
        DateTime(0),
        max_time,
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
    job.def;
    desc = job.desc,
    user = job.user,
    max_time = job.max_time,
    parents = job.parents,
    children = job.children,
)

# Ideas from `@test`, see https://github.com/JuliaLang/julia/blob/6bd952c/stdlib/Test/src/Test.jl#L331-L341
"""
    @job(ex, kwargs...)

Create a `Job` from an `Expr`, not a `Function`.

# Examples
```@repl
a = @job sleep(5) user="me" desc="Sleep for 5 seconds" children=[b]
b = @job run(`pwd` & `ls`) user="me" desc="Run some commands" parents=[a]
```
"""
macro job(ex, kwargs...)
    ex = :(Job(() -> $(esc(ex))))
    for kwarg in kwargs
        kwarg isa Expr && kwarg.head === :(=) || error("argument $kwarg is invalid!")
        kwarg.head = :kw
        push!(ex.args, kwarg)
    end
    return ex
end

const JOB_REGISTRY = Job[]

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
        job.ref = @async begin
            job.status = RUNNING
            job.start_time = now()
            if !isexecuted(job)
                push!(JOB_REGISTRY, job)
            end
            __run!(job)
        end
        return job
    else
        job.status = PENDING
        return _run!(job)
    end
end
function __run!(job::Job)
    # See https://github.com/JuliaLang/julia/issues/21130#issuecomment-288423284
    @try begin
        global result = job.def()
        @catch e
        job.stop_time = now()
        @error "come across `$e` when running!"
        job.status = e isa InterruptException ? INTERRUPTED : FAILED
        return e
        @else
        job.stop_time = now()
        job.status = SUCCEEDED
        return result
        @finally
        job.count += 1
    end
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
    df = DataFrame(
        id = [job.id for job in JOB_REGISTRY],
        user = [job.user for job in JOB_REGISTRY],
        created_time = map(createdtime, JOB_REGISTRY),
        start_time = map(starttime, JOB_REGISTRY),
        stop_time = map(stoptime, JOB_REGISTRY),
        elapsed = map(elapsed, JOB_REGISTRY),
        status = map(getstatus, JOB_REGISTRY),
        times = map(ntimes, JOB_REGISTRY),
        desc = map(description, JOB_REGISTRY),
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

isexecuted(job::Job) = job in JOB_REGISTRY

"""
    ntimes(id::Integer)
    ntimes(job::Job)

Return how many times a `Job` has been rerun.
"""
ntimes(id::Integer) = ntimes(first(filter(x -> x.id == id, JOB_REGISTRY)))
ntimes(job::Job) = Int(job.count)

"""
    getstatus(x::Job)

Get the current status of the `Job`.
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
getresult(job::Job) = isexited(job) ? Some(fetch(job.ref)) : nothing

"""
    description(job::Job)

Return the description of a `Job`.
"""
description(job::Job) = job.desc

# From https://github.com/cihga39871/JobSchedulers.jl/blob/aca52de/src/jobs.jl#L6-L10
function generate_id()
    time_value = (now().instant.periods.value - 63749462400000) << 16
    rand_value = rand(UInt16)
    return time_value + rand_value
end

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
        schedule(job.ref, InterruptException(); error = true)
    end
    return job
end

Base.wait(job::Job) = wait(job.ref)

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
        show(io, job.def)
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
