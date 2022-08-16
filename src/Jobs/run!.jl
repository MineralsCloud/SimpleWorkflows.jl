import ..SimpleWorkflows: run!

"""
    run!(job::Job; n=1, δt=1)

Run a `Job` with maximum `n` attempts, with each attempt separated by `δt` seconds.
"""
function run!(job::Job; n = 1, δt = 1)
    @assert isinteger(n) && n >= 1
    for _ in 1:n
        if !issucceeded(job)
            run_inner!(job)
        end
        if issucceeded(job)
            break  # Stop immediately
        end
        if !iszero(δt)  # Still unsuccessful
            sleep(δt)  # `if-else` is faster than `sleep(0)`
        end
    end
    return job
end
function run_inner!(job::Job)  # Do not export!
    if ispending(job)
        if !isexecuted(job)
            push!(JOB_REGISTRY, job => nothing)
        end
        JOB_REGISTRY[job] = @async run_core!(job)
    else
        job.status = PENDING
        return run_inner!(job)
    end
end
function run_core!(job::Job)  # Do not export!
    job.status = RUNNING
    job.start_time = now()
    reify!(job.thunk)
    job.stop_time = now()
    result = getresult(job.thunk)
    if result isa ErrorException
        job.status = result isa InterruptException ? INTERRUPTED : FAILED
    else
        job.status = SUCCEEDED
    end
    job.count += 1
    return job
end