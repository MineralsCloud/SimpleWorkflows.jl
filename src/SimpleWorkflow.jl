module SimpleWorkflow

using AbInitioSoftwareBase: load
using ColorTypes: RGB
using Dates: unix2datetime, format
using Distributed: Future, @spawn
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
    run!,
    fromfile,
    @job

abstract type JobStatus end
struct Pending <: JobStatus end
struct Running <: JobStatus end
abstract type Exited <: JobStatus end
struct Succeeded <: Exited end
struct Failed <: Exited end
struct Interrupted <: Exited end

mutable struct Timer
    start::Float64
    stop::Float64
    Timer() = new()
end

mutable struct Logger
    out::String
    err::String
end

mutable struct JobRef
    status::JobStatus
    ref::Future
    JobRef() = new(Pending())
end

abstract type Job end
struct EmptyJob <: Job
    desc::String
    ref::JobRef
    timer::Timer
    EmptyJob(desc = "No description here.") = new(desc, JobRef(), Timer())
end
struct AtomicJob{T} <: Job
    def::T
    desc::String
    ref::JobRef
    timer::Timer
    log::Logger
    AtomicJob(def::T, desc = "No description here.") where {T} =
        new{T}(def, desc, JobRef(), Timer(), Logger("", ""))
end

function run!(x::AtomicJob{<:Base.AbstractCmd})
    out, err = Pipe(), Pipe()
    x.ref.ref = @spawn begin
        x.ref.status = Running()
        x.timer.start = time()
        ref = try
            run(pipeline(x.def, stdin = devnull, stdout = out, stderr = err))
        catch e
            @error "could not spawn process `$(x.def)`! Come across `$e`!"
            e
        finally
            x.timer.stop = time()
            close(out.in)
            close(err.in)
        end
        if ref isa Exception  # Include all cases?
            if ref isa InterruptException
                x.ref.status = Interrupted()
            else
                x.ref.status = Failed()
            end
            x.log.err = String(read(err))
        else
            x.ref.status = Succeeded()
            x.log.out = String(read(out))
        end
        ref
    end
    return x
end
function run!(x::AtomicJob{<:Function})
    x.ref.ref = @spawn begin
        x.ref.status = Running()
        x.timer.start = time()
        ref = try
            x.def()
        catch e
            @error "could not spawn process `$(x.def)`! Come across `$e`!"
            e
        finally
            x.timer.stop = time()
        end
        if ref isa Exception  # Include all cases?
            if ref isa InterruptException
                x.ref.status = Interrupted()
            else
                x.ref.status = Failed()
            end
        else
            x.ref.status = Succeeded()
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

macro job(x::Function, desc = "No description here.")
    return :(AtomicJob(() -> x, $desc))
end
macro job(x::Base.AbstractCmd, desc = "No description here.")
    return :(AtomicJob(x, $desc))
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

function fromfile(cfgfile)
    config = load(cfgfile)
    @assert haskey(config, "actions")
    map(config["actions"]) do rule
        @assert all(haskey(rule, key) for key in ("inputs", "outputs"))
        if haskey(rule, "command")
            return ExternalAtomicJob(Script(rule["command"], mktemp()))
        elseif haskey(rule, "function")
            return InternalAtomicJob(() -> evalfile(rule["function"]))
        else
            @error "unknown action provided! It should be either `\"command\"` or `\"function\"`!"
            return EmptyJob()
        end
    end
end

Base.wait(x::Job) = wait(x.ref.ref)

Base.show(io::IO, ::EmptyJob) = print(io, " empty job")
function Base.show(io::IO, job::AtomicJob)
    printstyled(io, " ", job.def; bold = true)
    if !ispending(job)
        print(
            io,
            " from ",
            format(starttime(job), "HH:MM:SS u dd, yyyy"),
            isrunning(job) ? ", still running..." :
            ", to " * format(stoptime(job), "HH:MM:SS u dd, yyyy"),
            ", uses ",
            elapsed(job),
            " seconds.",
        )
    else
        print(" pending...")
    end
end

include("graph.jl")

end
