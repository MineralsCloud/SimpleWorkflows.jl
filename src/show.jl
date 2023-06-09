function Base.show(io::IO, wf::Workflow)
    if get(io, :compact, false) || get(io, :typeinfo, nothing) == typeof(wf)
        Base.show_default(IOContext(io, :limit => true), wf)  # From https://github.com/mauro3/Parameters.jl/blob/ecbf8df/src/Parameters.jl#L556
    else
        println(io, summary(wf))
        println(io, " jobs:")
        for (i, job) in enumerate(wf.jobs)
            println(io, "  (", i, ") ", "id: ", job.id)
            if !isempty(job.description)
                print(io, ' '^6, "description: ")
                show(io, job.description)
                println(io)
            end
            print(io, ' '^6, "core: ")
            printf(io, job.core)
            print(io, '\n', ' '^6, "status: ")
            printstyled(io, getstatus(job); bold=true)
            if !ispending(job)
                print(
                    io,
                    '\n',
                    ' '^6,
                    "from: ",
                    format(starttimeof(job), "dd-u-YYYY HH:MM:SS.s"),
                    '\n',
                    ' '^6,
                    "to: ",
                )
                if isrunning(job)
                    print(io, "still running...")
                else
                    println(io, format(endtimeof(job), "dd-u-YYYY HH:MM:SS.s"))
                    print(io, ' '^6, "uses: ", timecostof(job))
                end
            end
            println(io)
        end
    end
end
