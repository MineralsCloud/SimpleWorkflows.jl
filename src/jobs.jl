using DataFrames: DataFrame, sort, filter
using Dates: DateTime, Period, Day, now, format
using LegibleLambdas: @λ
using Serialization: serialize, deserialize

export AtomicJob
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
    outmsg,
    run!,
    interrupt!,
    initialize!,
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

abstract type Job end
# Reference: https://github.com/cihga39871/JobSchedulers.jl/blob/aca52de/src/jobs.jl#L35-L69
mutable struct AtomicJob <: Job
    id::Int64
    def::Function
    desc::String
    user::String
    created_time::DateTime
    start_time::DateTime
    stop_time::DateTime
    max_time::Period
    status::JobStatus
    outmsg::String
    ref::Union{Task,Nothing}
    count::UInt64
    AtomicJob(def; desc = "", user = "", max_time = Day(1)) = new(
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
        0,
    )
end
AtomicJob(cmd::Base.AbstractCmd; kwargs...) = AtomicJob(@λ(() -> run(cmd)); kwargs...)
AtomicJob(job::AtomicJob) =
    AtomicJob(job.def; desc = job.desc, user = job.user, max_time = job.max_time)

const JOB_REGISTRY = Job[]

isinitialized(job::AtomicJob) =
    job.start_time == job.stop_time == DateTime(0) &&
    job.status === PENDING &&
    job.ref === nothing

function run!(job::AtomicJob; attempts = 5, sleep_attempt = 3)
    @assert isinteger(attempts) && attempts >= 1
    if attempts > 1
        job = run!(job; attempts = 1)
        if !issucceeded(job)
            sleep(sleep_attempt)
            return run!(job; attempts = attempts - 1, sleep_attempt = sleep_attempt)
        else
            return job
        end
    else  # attempts == 1
        if isinitialized(job)
            job.ref = @async begin
                job.status = RUNNING
                job.start_time = now()
                if !isexecuted(job)
                    push!(JOB_REGISTRY, job)
                end
                _run!(job)
            end
            return job
        else
            job = initialize!(job)
            return run!(job; attempts = 1)
        end
    end
end
function _run!(job::AtomicJob)
    try
        result = job.def()
        job.stop_time = now()
        job.status = SUCCEEDED
        return result
    catch e
        job.stop_time = now()
        @error "come across `$e` when running!"
        job.status = e isa InterruptException ? INTERRUPTED : FAILED
        return e
    finally
        job.count += 1
    end
end

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

query(id::Integer) = filter(row -> row.id == id, queue())
query(ids::AbstractVector{<:Integer}) = map(id -> query(id), ids)

isexecuted(job::Job) = job in JOB_REGISTRY

ntimes(id::Integer) = ntimes(first(filter(x -> x.id == id, JOB_REGISTRY)))
ntimes(job::Job) = Int(job.count)

getstatus(x::Job) = x.status

ispending(x::Job) = getstatus(x) === PENDING

isrunning(x::Job) = getstatus(x) === RUNNING

isexited(x::Job) = getstatus(x) in (SUCCEEDED, FAILED, INTERRUPTED)

issucceeded(x::Job) = getstatus(x) === SUCCEEDED

isfailed(x::Job) = getstatus(x) === FAILED

isinterrupted(x::Job) = getstatus(x) === INTERRUPTED

createdtime(x::Job) = x.created_time

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

function interrupt!(job::AtomicJob)
    if isexited(job)
        @info "the job $(job.id) has already exited!"
        return job
    elseif ispending(job)
        @info "the job $(job.id) has not started!"
        return job
    else
        schedule(job.ref, InterruptException(); error = true)
        return job
    end
end

function initialize!(job::AtomicJob)
    job.start_time = DateTime(0)
    job.stop_time = DateTime(0)
    job.status = PENDING
    job.outmsg = ""
    job.ref = nothing
    return job
end

Base.wait(x::Job) = wait(x.ref)

function Base.show(io::IO, job::AtomicJob)
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
