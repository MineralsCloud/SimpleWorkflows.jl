export eachjob

struct EachJob{T<:AbstractWorkflow}
    wf::T
end

eachjob(wf::AbstractWorkflow) = EachJob(wf)

Base.iterate(iter::EachJob) = iterate(listjobs(iter.wf))
Base.iterate(iter::EachJob, state) = iterate(listjobs(iter.wf), state)

Base.eltype(iter::EachJob) = eltype(listjobs(iter.wf))

Base.length(iter::EachJob) = length(listjobs(iter.wf))

Base.size(iter::EachJob, dim...) = size(listjobs(iter.wf), dim...)

Base.getindex(iter::EachJob, i) = getindex(listjobs(iter.wf), i)

Base.firstindex(iter::EachJob) = 1

Base.lastindex(iter::EachJob) = length(iter)
