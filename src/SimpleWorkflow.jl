module SimpleWorkflow

using ColorTypes: RGB
using Dates: unix2datetime, format
using Distributed: Future, @spawn

export ExternalAtomicJob, InternalAtomicJob, Script
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
    @fun,
    @shell,
    @script

abstract type JobStatus end
struct Pending <: JobStatus end
struct Running <: JobStatus end
abstract type Exited <: JobStatus end
struct Succeeded <: Exited end
struct Failed <: Exited end
struct Interrupted <: Exited end

struct Script
    content::String
    path::String
    chdir::Bool
    mode::Integer
end
Script(content, path; chdir = false, mode = 0o777) = Script(content, path, chdir, mode)

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
    EmptyJob(desc = "Unnamed") = new(desc, JobRef(), Timer())
end
abstract type AtomicJob <: Job end
struct ExternalAtomicJob{T} <: AtomicJob
    cmd::T
    desc::String
    ref::JobRef
    timer::Timer
    log::Logger
    ExternalAtomicJob(cmd::T, desc = "Unnamed") where {T} =
        new{T}(cmd, desc, JobRef(), Timer(), Logger("", ""))
end
struct InternalAtomicJob <: AtomicJob
    fun::Function
    desc::String
    ref::JobRef
    timer::Timer
    log::Logger
    InternalAtomicJob(fun, desc = "Unnamed") =
        new(fun, desc, JobRef(), Timer(), Logger("", ""))
end

function run!(x::ExternalAtomicJob{<:Base.AbstractCmd})
    out, err = Pipe(), Pipe()
    x.ref.ref = @spawn begin
        x.ref.status = Running()
        x.timer.start = time()
        ref = try
            run(pipeline(x.cmd, stdin = devnull, stdout = out, stderr = err))
        catch e
            @error "could not spawn process `$(x.cmd)`! Come across `$e`!"
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
function run!(x::ExternalAtomicJob{Script})
    out, err = Pipe(), Pipe()
    path = abspath(expanduser(x.cmd.path))
    mkpath(dirname(path))
    open(path, "w") do io
        write(io, x.cmd.content)
    end
    chmod(path, x.cmd.mode)
    if x.cmd.chdir == true
        cwd = pwd()
        cd(basename(path))
    end
    x.ref.ref = @spawn begin
        x.ref.status = Running()
        x.timer.start = time()
        ref = try
            run(pipeline(`$path`, stdin = devnull, stdout = out, stderr = err))
        catch e
            @error "could not spawn process `$(x.cmd)`! Come across `$e`!"
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
    if @isdefined cwd
        cd(cwd)
    end
    return x
end
function run!(x::InternalAtomicJob)
    x.ref.ref = @spawn begin
        x.ref.status = Running()
        x.timer.start = time()
        ref = try
            x.fun()
        catch e
            @error "could not spawn process `$(x.fun)`! Come across `$e`!"
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

macro fun(x)
    return :(InternalAtomicJob(() -> $(esc(x))))
end

macro shell(x)
    return :(ExternalAtomicJob($(esc(x))))
end

macro script(cmd, file = mktemp(cleanup = false)[1])
    return :(ExternalAtomicJob(Script($(esc(cmd)), $(esc(file)))))
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

Base.wait(x::Job) = wait(x.ref.ref)

Base.show(io::IO, ::EmptyJob) = print(io, " empty job")
function Base.show(io::IO, job::AtomicJob)
    printstyled(io, " ", job isa ExternalAtomicJob ? job.cmd : job.fun; bold = true)
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
