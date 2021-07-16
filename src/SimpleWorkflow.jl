module SimpleWorkflow

using DataFrames: DataFrame, sort
using Dates: DateTime, Period, Day, now, format
using Distributed: Future, @spawn
using IOCapture: capture
using Serialization: serialize, deserialize
using UUIDs: UUID, uuid1

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
    queue

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
    id::UUID
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
        uuid1(),
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
    id = UUID[],
    def = Any[],
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
    job.ref === nothing

function run!(x::AtomicJob)
    x.ref = @spawn begin
        x.status = RUNNING
        x.start_time = now()
        push!(
            JOB_REGISTRY,
            (x.id, x.def, x.created_time, x.start_time, nothing, nothing, x.status, x),
        )
        ref = try
            captured = capture() do
                _call(x.def)
            end
            captured.value
        catch e
            @error "could not spawn process `$(x.def)`! Come across `$e`!"
            e
        finally
            x.stop_time = now()
            row = filter(row -> row.id == x.id, JOB_REGISTRY)
            row.stop_time = x.stop_time
            row.duration = x.stop_time - x.start_time
            x.outmsg = captured.output
        end
        if ref isa Exception  # Include all cases?
            if ref isa InterruptException
                x.status = INTERRUPTED
            else
                x.status = FAILED
            end
        else
            x.status = SUCCEEDED
        end
        row = filter(row -> row.id == x.id, JOB_REGISTRY)
        row.status = x.status
        ref
    end
    return x
end

_call(cmd::Base.AbstractCmd) = run(cmd)
_call(f) = f()

function queue(; all = true)
    for row in eachrow(JOB_REGISTRY)
        job = row.job
        row.stop_time = stoptime(job)
        row.duration = elapsed(job)
        row.status = getstatus(job)
    end
    if all
        return sort(JOB_REGISTRY, :status)
    else
    end
end

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

outmsg(x::AtomicJob) = isrunning(x) ? nothing : x.outmsg

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
