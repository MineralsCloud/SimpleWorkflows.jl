using Query

using EasyJobsBase: Job

export maketable

function maketable(sink, registry)
    return @from job in registry begin
        @select {
            id = job.id,
            def = string(job.core),
            created_time = job.created_time,
            start_time = starttime(job),
            stop_time = stoptime(job),
            duration = elapsed(job),
            status = getstatus(job),
        }
        @collect sink
    end
end
