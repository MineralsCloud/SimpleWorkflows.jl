using Dates: format
using EasyJobsBase: ispending, isrunning, starttimeof, endtimeof, timecostof, printf
using Graphs: ne

# See https://docs.julialang.org/en/v1/manual/types/#man-custom-pretty-printing
function Base.show(io::IO, wf::Workflow)
    if get(io, :compact, false)
        print(IOContext(io, :limit => true, :compact => true), summary(wf))
    else
        njobs, nedges = nv(wf.graph), ne(wf.graph)
        print(io, summary(wf), '(', njobs, " jobs, ", nedges, " edges)")
    end
end
function Base.show(io::IO, ::MIME"text/plain", wf::Workflow)
    println(io, summary(wf))
    for (i, job) in enumerate(wf.jobs)
        println(io, " [", i, "] ", "id: ", job.id)
        if !isempty(job.description)
            print(io, ' '^5, "description: ")
            show(io, job.description)
            println(io)
        end
        print(io, ' '^5, "core: ")
        printf(io, job.core)
        print(io, '\n', ' '^5, "status: ")
        printstyled(io, getstatus(job); bold=true)
        if !ispending(job)
            print(
                io,
                '\n',
                ' '^5,
                "from: ",
                format(starttimeof(job), "dd-u-YYYY HH:MM:SS.s"),
                '\n',
                ' '^5,
                "to: ",
            )
            if isrunning(job)
                print(io, "still running...")
            else
                println(io, format(endtimeof(job), "dd-u-YYYY HH:MM:SS.s"))
                print(io, ' '^5, "uses: ", timecostof(job))
            end
        end
        println(io)
    end
end
