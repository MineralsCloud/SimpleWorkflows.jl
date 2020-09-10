module SimpleWorkflow

using Dates: unix2datetime
using Distributed: Future, @spawn
using UUIDs: UUID, uuid4

abstract type JobStatus end
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

mutable struct JobRef
    ref::Future
    status::JobStatus
    JobRef() = new()
end

abstract type Job end
abstract type AtomicJob <: Job end
struct ExternalAtomicJob <: AtomicJob
    cmd
    name::String
    id::UUID
    ref::JobRef
    timer::Timer
    logger
    ExternalAtomicJob(cmd, name = "Unnamed") =
        new(cmd, name, uuid4(), JobRef(), Timer(), "")
end

function Base.run(x::ExternalAtomicJob)
    x.ref.ref = @spawn begin
        x.timer.start = time()
        ref = try
            run(x.cmd; wait = true)  # Must wait
        catch e
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

Base.:(==)(a::Job, b::Job) = false
Base.:(==)(a::T, b::T) where {T<:Job} = a.id == b.id

getstatus(x::AtomicJob) = x.ref.status

isrunning(x::AtomicJob) = getstatus(x) isa Running

issucceeded(x::AtomicJob) = getstatus(x) isa Succeeded

isfailed(x::AtomicJob) = getstatus(x) isa Failed

isinterrupted(x::AtomicJob) = getstatus(x) isa Interrupted

starttime(x::AtomicJob) = unix2datetime(x.timer.start)

stoptime(x::AtomicJob) = isrunning(x) ? nothing : unix2datetime(x.timer.stop)

timecost(x::AtomicJob) = isrunning(x) ? time() - starttime(x) : stoptime(x) - starttime(x)

end
