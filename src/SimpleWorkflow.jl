module SimpleWorkflow

using Dates: unix2datetime, format
using Distributed: Future, @spawn

export ExternalAtomicJob
export getstatus,
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
    name::String
    ref::JobRef
    timer::Timer
    EmptyJob(name = "Unnamed") = new(name, JobRef(), Timer())
end
abstract type AtomicJob <: Job end
struct ExternalAtomicJob <: AtomicJob
    cmd
    name::String
    ref::JobRef
    timer::Timer
    log::Logger
    ExternalAtomicJob(cmd, name = "Unnamed") =
        new(cmd, name, JobRef(), Timer(), Logger("", ""))
end

function run!(x::ExternalAtomicJob)
    out, err = Pipe(), Pipe()
    x.ref.ref = @spawn begin
        x.ref.status = Running()
        x.timer.start = time()
        ref = try
            run(pipeline(x.cmd, stdin = devnull, stdout = out, stderr = err))
        catch e
            @warn("could not spawn $(x.cmd)!")
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
function run!(x::EmptyJob)
    x.ref.ref = @spawn begin
        x.timer.start = x.timer.stop = time()
        x.ref.status = Succeeded()
        nothing
    end
    return x
end

getstatus(x::Job) = x.ref.status

ispending(x::Job) = getstatus(x) isa Pending

isrunning(x::Job) = getstatus(x) isa Running

isexited(x::Job) = getstatus(x) isa Exited

issucceeded(x::Job) = getstatus(x) isa Succeeded

isfailed(x::Job) = getstatus(x) isa Failed

isinterrupted(x::Job) = getstatus(x) isa Interrupted

starttime(x::Job) = ispending(x) ? nothing : unix2datetime(x.timer.start)

stoptime(x::Job) = isexited(x) ? unix2datetime(x.timer.stop) : nothing

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

Base.wait(x::Job) = wait(x.ref.ref)

Base.show(io::IO, ::EmptyJob) = print(io, " empty job")
function Base.show(io::IO, job::AtomicJob)
    printstyled(io, " ", job.cmd; bold = true)
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
