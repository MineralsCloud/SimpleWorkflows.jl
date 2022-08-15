module Thunks

export Thunk, reify!, getresult

mutable struct Thunk
    f
    args::Tuple
    kwargs::NamedTuple
    evaluated::Bool
    result
    Thunk(f, args, kwargs = NamedTuple()) = new(f, args, kwargs, false, nothing)
end
Thunk(f) = (args...; kwargs...) -> Thunk(f, args, NamedTuple(kwargs))

function reify!(thunk::Thunk)
    if thunk.evaluated
        return getresult(thunk)
    else
        try
            global result = thunk.f(thunk.args...; thunk.kwargs...)
        catch e
            setresult!(thunk, e)
            return e
        else
            setresult!(thunk, result)
            return result
        end
    end
end

getresult(thunk::Thunk) = thunk.result

function setresult!(thunk::Thunk, result)
    thunk.result = result
    thunk.evaluated = true
    # Clear to allow garbage collection
    thunk.args = ()
    thunk.kwargs = NamedTuple()
    return thunk
end

end
