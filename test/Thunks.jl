module Thunks

using SimpleWorkflows.Thunks: Thunk, ErredResult, reify!, getresult
using Test: @testset, @test

@testset "Test `reify!` `Thunk`s" begin
    a = Thunk(x -> 3x, 4)
    reify!(a)
    @test getresult(a) == Some(12)
    b = Thunk(+, 4, 5)
    reify!(b)
    @test getresult(b) == Some(9)
    c = Thunk(sleep)(1)
    @test getresult(c) === nothing  # `c` has not been evaluated
    reify!(c)  # `c` has been evaluated
    @test getresult(c) === Some(nothing)
    f(args...; kwargs...) = collect(kwargs)
    d = Thunk(f)(1, 2, 3; x = 1.0, y = 4, z = "5")
    reify!(d)
    @test something(getresult(d)) == [:x => 1.0, :y => 4, :z => "5"]
end

@testset "Test `getresult` with an `ErredResult`" begin
    i = Thunk(sin, "string")
    reify!(i)
    @test something(getresult(i)).thrown isa MethodError
    j = Thunk(error, "an error occurred!")
    reify!(j)
    @test something(getresult(j)).thrown isa ErrorException
    struct MyNonExceptionError
        msg::String
    end
    k = Thunk(() -> throw(MyNonExceptionError("an error occurred!")), ())
    reify!(k)
    @test something(getresult(k)).thrown isa MyNonExceptionError
end

end
