module SimpleWorkflow

using AbInitioSoftwareBase: load
using ColorTypes: RGB
using Dates: DateTime, Period, Day, unix2datetime, format, now
using Distributed: Future, @spawn
using IOCapture: capture
using Serialization: serialize, deserialize

export AtomicJob
export color,
    getstatus,
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
    errmsg,
    run!

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
    def::T
    desc::String
    user::String
    created_time::DateTime
    start_time::DateTime
    stop_time::DateTime
    max_time::Period
    status::JobStatus
    ref::Future
    AtomicJob(
        def::T;
        desc = "No description here.",
        user = "",
        max_time = Day(1),
    ) where {T} = new{T}(
        def,
        desc,
        user,
        now(),
        DateTime(0),
        DateTime(0),
        max_time,
        Pending(),
        Future(),
    )
end

function run!(x::AtomicJob{<:Base.AbstractCmd})
    x.ref = @spawn begin
        x.status = Running()
        x.start_time = now()
        ref = try
            capture() do
                run(x.def)
            end
        catch e
            @error "could not spawn process `$(x.def)`! Come across `$e`!"
            e
        finally
            x.stop_time = now()
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
        ref
    end
    return x
end
function run!(x::AtomicJob{<:Function})
    x.ref = @spawn begin
        x.status = Running()
        x.start_time = now()
        ref = try
            capture() do
                x.def()
            end
        catch e
            @error "could not spawn process `$(x.def)`! Come across `$e`!"
            e
        finally
            x.stop_time = now()
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
        ref
    end
    return x
end
function run!(x::DistributedJob)
    x.ref.ref = @spawn begin
        x.ref.status = Running()
        x.timer.start = time()
        ref = map(x.def) do job
            @async run!(job)
        end
        x.timer.stop = time()
        if all(issucceeded(job) for job in x.def)
            x.ref.status = Succeeded()
        elseif any(isinterrupted(job) for job in x.def)
            x.ref.status = Interrupted()
        else
            x.ref.status = Failed()
        end
        ref
    end
    return x
end
function run!(x::EmptyJob)
    x.ref.ref = @spawn begin
        x.timer.start = x.timer.stop = time()
        x.ref.status = Succeeded()
        nothing
    end
    return x
end

color(::Pending) = RGB(0.0, 0.0, 1.0)  # Blue
color(::Running) = RGB(1.0, 1.0, 0.0)  # Yellow
color(::Succeeded) = RGB(0.0, 0.502, 0.0)  # Green
color(::Failed) = RGB(1.0, 0.0, 0.0)  # Red
color(::Interrupted) = RGB(1.0, 0.647, 0.0)  # Orange

getstatus(x::Job) = x.ref.status

ispending(x::Job) = getstatus(x) isa Pending

isrunning(x::Job) = getstatus(x) isa Running

isexited(x::Job) = getstatus(x) isa Exited

issucceeded(x::Job) = getstatus(x) isa Succeeded

isfailed(x::Job) = getstatus(x) isa Failed

isinterrupted(x::Job) = getstatus(x) isa Interrupted

starttime(x::Job) = ispending(x) ? nothing : unix2datetime(x.timer.start)

stoptime(x::Job) = isexited(x) ? unix2datetime(x.timer.stop) : nothing

getresult(x::Job) = isexited(x) ? Some(fetch(x.ref.ref)) : nothing

description(x::Job) = x.desc

function elapsed(x::Job)
    start = unix2datetime(x.timer.start)
    if ispending(x)
        return
    elseif isrunning(x)
        return unix2datetime(time()) - start
    else  # Exited
        return unix2datetime(x.timer.stop) - start
    end
end

outmsg(x::AtomicJob) = isrunning(x) ? nothing : x.log.out
outmsg(::EmptyJob) = ""

errmsg(x::AtomicJob) = isrunning(x) ? nothing : x.log.err
errmsg(::EmptyJob) = ""

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

Base.wait(x::Job) = wait(x.ref.ref)

Base.show(io::IO, ::EmptyJob) = print(io, " empty job")
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
