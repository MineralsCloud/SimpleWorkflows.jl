import EasyJobsBase: chain!, follow!, pipe!, →, ←, ↠, ↞, ⇒, ⇐

export chain!, follow!, pipe!, →, ←, ↠, ↞, ⇒, ⇐

for (func, (op₁, op₂)) in zip((:chain!, :follow!, :pipe!), ((:→, :←), (:↠, :↞), (:⇒, :⇐)))
    @eval begin
        $func(x::AbstractWorkflow, y::AbstractWorkflow) =
            $func(last(eachjob(x)), first(eachjob(y)))
        $func(x::AbstractWorkflow, y::AbstractWorkflow, z::AbstractWorkflow...) =
            foldr($func, (x, y, z...))
        $op₁(x::AbstractWorkflow, y::AbstractWorkflow) = $func(x, y)
        $op₂(y::AbstractWorkflow, x::AbstractWorkflow) = $op₁(x, y)
    end
end
