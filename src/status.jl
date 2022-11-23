import EasyJobsBase:
    getstatus,
    pendingjobs,
    runningjobs,
    exitedjobs,
    succeededjobs,
    failedjobs,
    interruptedjobs

export getstatus,
    pendingjobs, runningjobs, exitedjobs, succeededjobs, failedjobs, interruptedjobs

"""
    getstatus(wf::AbstractWorkflow)

Get the current status of `Job`s in a `AbstractWorkflow`.
"""
getstatus(wf::Workflow) = getstatus(wf.jobs)
getstatus(wf::AutosaveWorkflow) = getstatus(wf.wf)

# See https://docs.julialang.org/en/v1/manual/documentation/#Advanced-Usage
for (func, adj) in zip(
    (
        :pendingjobs,
        :runningjobs,
        :exitedjobs,
        :succeededjobs,
        :failedjobs,
        :interruptedjobs,
    ),
    ("pending", "running", "exited", "succeeded", "failed", "interrupted"),
)
    name = string(func)
    @eval begin
        """
            $($name)(wf::AbstractWorkflow)

        Filter only the $($adj) jobs in a `Workflow`.
        """
        $func(wf::Workflow) = $func(wf.jobs)
        $func(wf::AutosaveWorkflow) = $func(wf.wf)
    end
end
