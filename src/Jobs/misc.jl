import ..Thunks: getresult

export ntimes, description, createdtime, starttime, stoptime, elapsed, interrupt!, getresult

"""
    ntimes(id::Integer)
    ntimes(job::Job)

Return how many times a `Job` has been rerun.
"""
ntimes(id::Integer) = ntimes(first(filter(x -> x.id == id, JOB_REGISTRY)))
ntimes(job::Job) = Int(job.count)

"""
    description(job::Job)

Return the description of a `Job`.
"""
description(job::Job) = job.desc

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
        return nothing
    elseif isrunning(job)
        return now() - job.start_time
    else  # Exited
        return job.stop_time - job.start_time
    end
end

"""
    getresult(job::Job)

Get the running result of a `Job`.

The result is wrapped by a `Some` type. Use `something` to retrieve its value.
If it is `nothing`, the `Job` is not finished.
"""
getresult(job::Job) = isexited(job) ? getresult(job.thunk) : nothing
