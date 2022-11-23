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
    getstatus(wf::Workflow)

Get the current status of `Job`s in a `Workflow`.
"""
getstatus(wf::Workflow) = getstatus(wf.jobs)
getstatus(wf::AutosaveWorkflow) = getstatus(wf.wf)

# See https://docs.julialang.org/en/v1/manual/documentation/#Advanced-Usage
for func in
    (:pendingjobs, :runningjobs, :exitedjobs, :succeededjobs, :failedjobs, :interruptedjobs)
    name = string(func)
    @eval begin
        """
            $($name)(wf::Workflow)

        Filter only the pending jobs in a `Workflow`.
        """
        $func(wf::Workflow) = $func(wf.jobs)
        $func(wf::AutosaveWorkflow) = $func(wf.wf)
    end
end
