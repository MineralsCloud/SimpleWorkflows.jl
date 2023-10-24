Base.iterate(wf::Workflow, state=firstindex(wf)) = iterate(wf.jobs, state)

Base.eltype(::Type{Workflow{T}}) where {T} = T

Base.length(wf::Workflow) = length(wf.jobs)

Base.getindex(wf::Workflow, i) = getindex(wf.jobs, i)

Base.firstindex(wf::Workflow) = 1

Base.lastindex(wf::Workflow) = length(wf.jobs)
