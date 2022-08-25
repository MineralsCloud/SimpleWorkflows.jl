using DataFrames: DataFrame, sort

export initialize!, queue, query, isexecuted

const JOB_REGISTRY = Dict{Job,Union{Nothing,Task}}()

function initialize!()
    empty!(JOB_REGISTRY)
    return nothing
end

"""
    queue(; sortby = :created_time)

Print all `Job`s that are pending, running, or finished as a table.

Accpetable arguments for `sortby` are `:created_time`, `:user`, `:start_time`, `:stop_time`,
`:elapsed`, `:status`, and `:times`.
"""
function queue(; sortby=:created_time)
    @assert sortby in
        (:created_time, :user, :start_time, :stop_time, :elapsed, :status, :times)
    jobs = collect(keys(JOB_REGISTRY))
    df = DataFrame(;
        id=[job.id for job in jobs],
        user=[job.user for job in jobs],
        created_time=map(createdtime, jobs),
        start_time=map(starttime, jobs),
        stop_time=map(stoptime, jobs),
        elapsed=map(elapsed, jobs),
        status=map(getstatus, jobs),
        times=map(ntimes, jobs),
        desc=map(description, jobs),
    )
    return sort(df, [:id, sortby])
end

"""
    query(id::Integer)
    query(ids::AbstractVector{<:Integer})

Query a specific (or a list of `Job`s) by its (theirs) ID.
"""
query(id::Integer) = filter(row -> row.id == id, queue())
query(ids::AbstractVector{<:Integer}) = map(id -> query(id), ids)

isexecuted(job::Job) = job in keys(JOB_REGISTRY)
