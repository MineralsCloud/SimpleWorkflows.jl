export chain, thread, fork, converge, spindle, →, ←, ⇶, ⬱, ⇉, ⭃

"""
    chain(x::Job, y::Job, z::Job...)

Chain multiple `Job`s one after another.
"""
function chain(x::Job, y::Job)
    if x == y
        throw(ArgumentError("a job cannot be followed by itself!"))
    else
        push!(x.children, y)
        push!(y.parents, x)
        return x
    end
end
chain(x::Job, y::Job, z::Job...) = foldr(chain, (x, y, z...))
"""
    →(x, y)

Chain two `Job`s.
"""
→(x::Job, y::Job) = chain(x, y)
"""
    ←(y, x)

Chain two `Job`s reversely.
"""
←(y::Job, x::Job) = x → y

"""
    thread(xs::AbstractVector{Job}, ys::AbstractVector{Job}, zs::AbstractVector{Job}...)

Chain multiple vectors of `Job`s, each `Job` in `xs` has a corresponding `Job` in `ys`.`
"""
function thread(xs::AbstractVector{Job}, ys::AbstractVector{Job})
    if size(xs) != size(ys)
        throw(DimensionMismatch("`xs` and `ys` must have the same size!"))
    end
    for (x, y) in zip(xs, ys)
        chain(x, y)
    end
    return xs
end
function thread(
    xs::AbstractVector{Job}, ys::AbstractVector{Job}, zs::AbstractVector{Job}...
)
    return foldr(thread, (xs, ys, zs...))
end
"""
    ⇶(xs, ys)

Chain two vectors of `Job`s.
"""
⇶(xs::AbstractVector{Job}, ys::AbstractVector{Job}) = thread(xs, ys)
"""
    ⬱(ys, xs)

Chain two vectors of `Job`s reversely.
"""
⬱(ys::AbstractVector{Job}, xs::AbstractVector{Job}) = xs ⇶ ys

"""
    fork(x::Job, ys::AbstractVector{Job})
    ⇉(x, ys)

Attach a group of parallel `Job`s (`ys`) to a single `Job` (`x`).
"""
function fork(x::Job, ys::AbstractVector{Job})
    for y in ys
        chain(x, y)
    end
    return x
end
const ⇉ = fork

"""
    converge(xs::AbstractVector{Job}, y::Job)
    ⭃(xs, y)

Finish a group a parallel `Job`s (`xs`) by a single `Job` (`y`).
"""
function converge(xs::AbstractVector{Job}, y::Job)
    for x in xs
        chain(x, y)
    end
    return xs
end
const ⭃ = converge

"""
    spindle(x::Job, ys::AbstractVector{Job}, z::Job)

Start from a `Job` (`x`), followed by a series of `Job`s (`ys`), finished by a single `Job` (`z`).
"""
spindle(x::Job, ys::AbstractVector{Job}, z::Job) = x ⇉ ys ⭃ z
