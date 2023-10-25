import EasyJobsBase:
    getstatus,
    ispending,
    isrunning,
    isexited,
    issucceeded,
    isfailed,
    filterpending,
    filterrunning,
    filterexited,
    filtersucceeded,
    filterfailed

export getstatus,
    ispending,
    isrunning,
    isexited,
    issucceeded,
    isfailed,
    filterpending,
    filterrunning,
    filterexited,
    filtersucceeded,
    filterfailed

"""
    ispending(wf::AbstractWorkflow)

Check if all jobs in the `AbstractWorkflow` are in a pending state.

Return `true` if all jobs are pending, otherwise, return `false`.
"""
ispending(wf::AbstractWorkflow) = all(ispending, wf)

"""
    isrunning(wf::AbstractWorkflow)

Check if any job in the `AbstractWorkflow` is currently running.

Return `true` if at least one job is running, otherwise, return `false`.
"""
isrunning(wf::AbstractWorkflow) = any(isrunning, wf)

"""
    isexited(wf::AbstractWorkflow)

Check if all jobs in the `AbstractWorkflow` have exited.

Return `true` if all jobs have exited, otherwise, return `false`.
"""
isexited(wf::AbstractWorkflow) = all(isexited, wf)

"""
    issucceeded(wf::AbstractWorkflow)

Check if all jobs in the `AbstractWorkflow` have successfully completed.

Return `true` if all jobs have succeeded, otherwise, return `false`.
"""
issucceeded(wf::AbstractWorkflow) = all(issucceeded, wf)

"""
    isfailed(wf::AbstractWorkflow)

Check if any job in the `AbstractWorkflow` has failed, given that all jobs have exited.

Return `true` if any job has failed after all jobs have exited, otherwise, return `false`.
"""
isfailed(wf::AbstractWorkflow) = isexited(wf) && any(isfailed, wf)

# See https://docs.julialang.org/en/v1/manual/documentation/#Advanced-Usage
for (func, adj) in zip(
    (:filterpending, :filterrunning, :filterexited, :filtersucceeded, :filterfailed),
    ("pending", "running", "exited", "succeeded", "failed"),
)
    name = string(func)
    @eval begin
        """
            $($name)(wf::AbstractWorkflow)

        Filter only the $($adj) jobs in a `Workflow`.
        """
        $func(wf::Workflow) = $func(collect(wf))
    end
end
