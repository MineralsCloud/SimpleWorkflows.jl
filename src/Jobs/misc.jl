"""
    ntimes(id::Integer)
    ntimes(job::Job)

Return how many times a `Job` has been rerun.
"""
ntimes(id::Integer) = ntimes(first(filter(x -> x.id == id, JOB_REGISTRY)))
ntimes(job::Job) = Int(job.count)

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
    description(job::Job)

Return the description of a `Job`.
"""
description(job::Job) = job.desc

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
        schedule(JOB_REGISTRY[job], InterruptException(); error = true)
    end
    return job
end

"""
    getresult(job::Job)

Get the running result of a `Job`.

The result is wrapped by a `Some` type. Use `something` to retrieve its value.
If it is `nothing`, the `Job` is not finished.
"""
getresult(job::Job) = isexited(job) ? Some(job.thunk.result) : nothing

Base.wait(job::Job) = wait(JOB_REGISTRY[job])
