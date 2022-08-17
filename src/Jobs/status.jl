export getstatus,
    ispending,
    isrunning,
    isexited,
    issucceeded,
    isfailed,
    isinterrupted,
    pendingjobs,
    runningjobs,
    exitedjobs,
    succeededjobs,
    failedjobs,
    interruptedjobs

"""
    getstatus(x::Job)

Get the current status of a `Job`.
"""
getstatus(job::Job) = job.status
getstatus(jobs::AbstractArray{Job}) = map(getstatus, jobs)

"Test if the `Job` is still pending."
ispending(job::Job) = getstatus(job) === PENDING

"Test if the `Job` is running."
isrunning(job::Job) = getstatus(job) === RUNNING

"Test if the `Job` has exited."
isexited(job::Job) = getstatus(job) in (SUCCEEDED, FAILED, INTERRUPTED)

"Test if the `Job` was successfully run."
issucceeded(job::Job) = getstatus(job) === SUCCEEDED

"Test if the `Job` failed during running."
isfailed(job::Job) = getstatus(job) === FAILED

"Test if the `Job` was interrupted during running."
isinterrupted(job::Job) = getstatus(job) === INTERRUPTED

"""
    pendingjobs(jobs)

Filter only the pending jobs in a sequence of `Job`s.
"""
pendingjobs(jobs) = filter(ispending, jobs)

"""
    runningjobs(jobs)

Filter only the running jobs in a sequence of `Job`s.
"""
runningjobs(jobs) = filter(isrunning, jobs)

"""
    exitedjobs(jobs)

Filter only the exited jobs in a sequence of `Job`s.
"""
exitedjobs(jobs) = filter(isexited, jobs)

"""
    succeededjobs(jobs)

Filter only the succeeded jobs in a sequence of `Job`s.
"""
succeededjobs(jobs) = filter(issucceeded, jobs)

"""
    failedjobs(jobs)

Filter only the failed jobs in a sequence of `Job`s.
"""
failedjobs(jobs) = filter(isfailed, jobs)

"""
    interruptedjobs(jobs)

Filter only the interrupted jobs in a sequence of `Job`s.
"""
interruptedjobs(jobs) = filter(isinterrupted, jobs)
