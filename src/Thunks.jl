module Thunks

export Thunk, reify!, getresult

"Capture errors and stack traces from a running `Thunk`."
struct ErredResult{T}
    thrown::T
    stacktrace::Base.StackTraces.StackTrace
end

# Idea from https://github.com/tbenst/Thunks.jl/blob/ff2a553/src/core.jl#L11-L20
"""
    Thunk(::Function, args::Tuple, kwargs::NamedTuple)
    Thunk(::Function, args...; kwargs...)
    Thunk(::Function)

Hold a `Function` and its arguments for lazy evaluation. Use `reify!` to evaluate.

# Examples
```jldoctest
julia> a = Thunk(x -> 3x, 4);

julia> reify!(a)
Some(12)

julia> b = Thunk(+, 4, 5);

julia> reify!(b)
Some(9)

julia> c = Thunk(sleep)(1);

julia> getresult(c)  # `c` has not been evaluated

julia> reify!(c)  # `c` has been evaluated
Some(nothing)

julia> f(args...; kwargs...) = collect(kwargs);

julia> d = Thunk(f)(1, 2, 3; x=1.0, y=4, z="5");

julia> reify!(d)
Some(Pair{Symbol, Any}[:x => 1.0, :y => 4, :z => "5"])

julia> e = Thunk(sin, "1");  # Catch errors

julia> reify!(e);
```
"""
mutable struct Thunk
    f
    args::Tuple
    kwargs::NamedTuple
    evaluated::Bool
    erred::Bool
    result::Union{Some,Nothing}
    function Thunk(f, args::Tuple, kwargs::NamedTuple=NamedTuple())
        return new(f, args, kwargs, false, false, nothing)
    end
end
Thunk(f, args...; kwargs...) = Thunk(f, args, NamedTuple(kwargs))
Thunk(f) = (args...; kwargs...) -> Thunk(f, args, NamedTuple(kwargs))

# See https://github.com/tbenst/Thunks.jl/blob/ff2a553/src/core.jl#L113-L123
"""
    reify!(thunk::Thunk)

Reify a `Thunk` into a value.

Compute the value of the expression.
Walk through the `Thunk`'s arguments and keywords, recursively evaluating each one,
and then evaluating the `Thunk`'s function with the evaluated arguments.

See also [`Thunk`](@ref).
"""
function reify!(thunk::Thunk)
    if thunk.evaluated
        return getresult(thunk)
    else
        try
            thunk.result = Some(thunk.f(thunk.args...; thunk.kwargs...))
        catch e
            thunk.erred = true
            s = stacktrace(catch_backtrace())
            thunk.result = Some(ErredResult(e, s))
        finally
            thunk.evaluated = true
        end
    end
end

"""
    getresult(thunk::Thunk)

Get the result of a `Thunk`. If `thunk` has not been evaluated, return `nothing`, else return a `Some`-wrapped result.
"""
getresult(thunk::Thunk) = thunk.evaluated ? thunk.result : nothing

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
        for v in args[1:(end - 1)]
            print(io, v, ", ")
        end
        print(io, args[end])
    end
    kwargs = thunk.kwargs
    if isempty(kwargs)
        print(io, ')')
    else
        print(io, ";")
        for (k, v) in zip(keys(kwargs)[1:(end - 1)], Tuple(kwargs)[1:(end - 1)])
            print(io, ' ', k, '=', v, ",")
        end
        print(io, ' ', keys(kwargs)[end], '=', kwargs[end])
        print(io, ')')
    end
end

function Base.show(io::IO, erred::ErredResult)
    if erred.thrown isa ErrorException
        show(io, erred.thrown)
    else
        showerror(io, erred.thrown)
    end
    return Base.show_backtrace(io, erred.stacktrace)
end

end
