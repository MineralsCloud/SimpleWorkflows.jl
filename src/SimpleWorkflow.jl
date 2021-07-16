module SimpleWorkflow

using DataFrames: DataFrame, sort
using Dates: DateTime, Period, Day, now, format
using Distributed: Future, @spawn
using IOCapture: capture
using Serialization: serialize, deserialize

export AtomicJob
export getstatus,
    getresult,
    description,
    ispending,
    isrunning,
    issucceeded,
    isfailed,
    isinterrupted,
    starttime,
    stoptime,
    elapsed,
    outmsg,
    run!,
    queue,
    query

@enum JobStatus begin
    PENDING
    RUNNING
    SUCCEEDED
    FAILED
    INTERRUPTED
end

abstract type Job end
# Reference: https://github.com/cihga39871/JobSchedulers.jl/blob/aca52de/src/jobs.jl#L35-L69
mutable struct AtomicJob{T} <: Job
    id::Int64
    def::T
    desc::String
    user::String
    created_time::DateTime
    start_time::DateTime
    stop_time::DateTime
    max_time::Period
    status::JobStatus
    outmsg::String
    ref::Union{Future,Nothing}
    AtomicJob(
        def::T;
        desc = "No description here.",
        user = "",
        max_time = Day(1),
    ) where {T} = new{T}(
        generate_id(),
        def,
        desc,
        user,
        now(),
        DateTime(0),
        DateTime(0),
        max_time,
        PENDING,
        "",
        nothing,
    )
end
AtomicJob(job::AtomicJob) =
    AtomicJob(job.def; desc = job.desc, user = job.user, max_time = job.max_time)

const JOB_REGISTRY = DataFrame(
    id = Int64[],
    def = String[],
    created_time = DateTime[],
    start_time = DateTime[],
    stop_time = Union{DateTime,Nothing}[],
    duration = Union{Period,Nothing}[],
    status = JobStatus[],
    job = Job[],
)

isnew(job::AtomicJob) =
    job.start_time == job.stop_time == DateTime(0) &&
    job.status == PENDING &&
    isempty(job.outmsg) &&
    job.ref === nothing

function run!(job::AtomicJob)
    job.ref = @spawn begin
        job.status = RUNNING
        job.start_time = now()
        _register!(job)
    end
    return job
end

function _register!(job::AtomicJob)
    push!(
        JOB_REGISTRY,
        (
            job.id,
            string(job.def),
            job.created_time,
            job.start_time,
            nothing,
            nothing,
            job.status,
            job,
        ),
    )
    result = _run!(job)
    # Update JOB_REGISTRY
    rows = query(job.id)
    rows[:, :status] .= job.status
    rows[:, :stop_time] .= job.stop_time
    rows[:, :duration] .= job.stop_time - job.start_time
    # Return the result
    return result
end

function _run!(job::AtomicJob)
    try
        captured = capture() do
            _call(job.def)
        end
        job.stop_time = now()
        job.status = SUCCEEDED
        job.outmsg = captured.output
        return captured.value
    catch e
        job.stop_time = now()
        @error "come across `$e` when running!"
        job.status = e isa InterruptException ? INTERRUPTED : FAILED
        if @isdefined captured  # The `captured` statement may fail
            job.outmsg = captured.output
        end
        return e
    end
end

_call(cmd::Base.AbstractCmd) = run(cmd)
_call(f) = f()

function queue(; all = true, sortby = :created_time)
    @assert sortby in (:id, :created_time, :start_time, :stop_time, :duration, :status)
    for row in eachrow(JOB_REGISTRY)
        job = row.job
        row.stop_time = stoptime(job)
        row.duration = elapsed(job)
        row.status = getstatus(job)
    end
    if all
        return sort(JOB_REGISTRY, sortby)
    else
    end
end

query(id::Union{Int64,AbstractVector{Int64}}) = filter(row -> row.id == id, JOB_REGISTRY)

getstatus(x::Job) = x.status

ispending(x::Job) = getstatus(x) === PENDING

isrunning(x::Job) = getstatus(x) === RUNNING

isexited(x::Job) = getstatus(x) in (SUCCEEDED, FAILED, INTERRUPTED)

issucceeded(x::Job) = getstatus(x) === SUCCEEDED

isfailed(x::Job) = getstatus(x) === FAILED

isinterrupted(x::Job) = getstatus(x) === INTERRUPTED

starttime(x::Job) = ispending(x) ? nothing : x.start_time

stoptime(x::Job) = isexited(x) ? x.stop_time : nothing

function elapsed(x::Job)
    if ispending(x)
        return
    elseif isrunning(x)
        return now() - x.start_time
    else  # Exited
        return x.stop_time - x.start_time
    end
end

getresult(x::Job) = isexited(x) ? Some(fetch(x.ref)) : nothing

description(x::Job) = x.desc

outmsg(x::AtomicJob) = isexited(x) ? x.outmsg : nothing

# From https://github.com/cihga39871/JobSchedulers.jl/blob/aca52de/src/jobs.jl#L6-L10
function generate_id()
    time_value = (now().instant.periods.value - 63749462400000) << 16
    rand_value = rand(UInt16)
    return time_value + rand_value
end

Base.wait(x::Job) = wait(x.ref)

function Base.show(io::IO, job::AtomicJob)
    println(io, summary(job))
    println(io, " id: ", job.id)
    print(io, " def: ")
    printstyled(io, job.def, '\n'; bold = true)
    println(io, " status: ", getstatus(job))
    if !ispending(job)
        print(
            io,
            " timing: from ",
            format(starttime(job), "HH:MM:SS u dd, yyyy"),
            isrunning(job) ? ", still running..." :
            ", to " * format(stoptime(job), "HH:MM:SS u dd, yyyy"),
            ", uses ",
            elapsed(job),
            " seconds.",
        )
    end
end

include("graph.jl")

end
