import ..Jobs: getstatus, pendingjobs, runningjobs, exitedjobs, failedjobs, interruptedjobs

export getstatus, pendingjobs, runningjobs, exitedjobs, failedjobs, interruptedjobs

for method in
    (:getstatus, :pendingjobs, :runningjobs, :exitedjobs, :failedjobs, :interruptedjobs)
    @eval begin
        $method(wf::Workflow) = $method(wf.jobs)
        $method(wf::SavedWorkflow) = $method(wf.wf)
    end
end
