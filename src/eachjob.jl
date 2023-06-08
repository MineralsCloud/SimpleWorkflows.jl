export eachjob

struct EachJob{T<:AbstractWorkflow}
    wf::T
end

eachjob(wf::AbstractWorkflow) = EachJob(wf)

Base.iterate(iter::EachJob) = iterate(getjobs(iter.wf))
Base.iterate(iter::EachJob, state) = iterate(getjobs(iter.wf), state)

Base.eltype(iter::EachJob) = eltype(getjobs(iter.wf))

Base.length(iter::EachJob) = length(getjobs(iter.wf))

Base.size(iter::EachJob, dim...) = size(getjobs(iter.wf), dim...)

Base.getindex(iter::EachJob, i) = getindex(getjobs(iter.wf), i)

Base.firstindex(iter::EachJob) = 1

Base.lastindex(iter::EachJob) = length(iter)
