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

function Base.show(io::IO, thunk::Thunk)
    if get(io, :compact, false) || get(io, :typeinfo, nothing) == typeof(thunk)
        Base.show_default(IOContext(io, :limit => true), thunk)  # From https://github.com/mauro3/Parameters.jl/blob/ecbf8df/src/Parameters.jl#L556
    else
        println(io, summary(thunk))
        print(io, ' ', "def: ")
        printfunc(io, thunk)
        println(io)
        println(io, " evaluated: ", thunk.evaluated)
        println(io, " result: ", thunk.result)
    end
end

function printfunc(io::IO, thunk::Thunk)
    print(io, thunk.f, '(')
    args = thunk.args
    if length(args) > 0
        for v in args[1:(end-1)]
            print(io, v, ", ")
        end
        print(io, args[end])
    end
    kwargs = thunk.kwargs
    if isempty(kwargs)
        print(io, ')')
    else
        print(io, ";")
        for (k, v) in zip(keys(kwargs)[1:(end-1)], Tuple(kwargs)[1:(end-1)])
            print(io, ' ', k, '=', v, ",")
        end
        print(io, ' ', keys(kwargs)[end], '=', kwargs[end])
        print(io, ')')
    end
end

end
