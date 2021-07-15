module SimpleWorkflow

using AbInitioSoftwareBase: load
using DataFrames: DataFrame
using Dates: DateTime, Period, Day, now
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

abstract type JobStatus end
struct Pending <: JobStatus end
struct Running <: JobStatus end
abstract type Exited <: JobStatus end
struct Succeeded <: Exited end
struct Failed <: Exited end
struct Interrupted <: Exited end

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
        Pending(),
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
    job.status == Pending() &&
    job.ref === nothing

function run!(x::AtomicJob)
    x.ref = @spawn begin
        x.status = Running()
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
                x.status = Interrupted()
            else
                x.status = Failed()
            end
        else
            x.status = Succeeded()
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
        return JOB_REGISTRY
    else
    end
end

getstatus(x::Job) = x.status

ispending(x::Job) = getstatus(x) isa Pending

isrunning(x::Job) = getstatus(x) isa Running

isexited(x::Job) = getstatus(x) isa Exited

issucceeded(x::Job) = getstatus(x) isa Succeeded

isfailed(x::Job) = getstatus(x) isa Failed

isinterrupted(x::Job) = getstatus(x) isa Interrupted

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

# function fromfile(cfgfile)
#     config = load(cfgfile)
#     @assert haskey(config, "actions")
#     map(config["actions"]) do rule
#         @assert all(haskey(rule, key) for key in ("inputs", "outputs"))
#         if haskey(rule, "command")
#             return AtomicJob(Script(rule["command"], mktemp()))
#         elseif haskey(rule, "function")
#             return AtomicJob(() -> evalfile(rule["function"]))
#         else
#             @error "unknown action provided! It should be either `\"command\"` or `\"function\"`!"
#             return EmptyJob()
#         end
#     end
# end

Base.wait(x::Job) = wait(x.ref)

# function Base.show(io::IO, job::AtomicJob)
#     printstyled(io, " ", job.def; bold = true)
#     if !ispending(job)
#         print(
#             io,
#             " from ",
#             format(starttime(job), "HH:MM:SS u dd, yyyy"),
#             isrunning(job) ? ", still running..." :
#             ", to " * format(stoptime(job), "HH:MM:SS u dd, yyyy"),
#             ", uses ",
#             elapsed(job),
#             " seconds.",
#         )
#     else
#         print(" pending...")
#     end
# end

include("graph.jl")

end
