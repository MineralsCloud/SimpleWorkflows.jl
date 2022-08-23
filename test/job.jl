using SimpleWorkflows: Job, ErredResult

@testset "Test `getresult` with an `ErredResult`" begin
    i = Job(() -> sin("string"))
    run!(i)
    @test something(getresult(i)).thrown isa MethodError
    j = Job(() -> error("an error occurred!"))
    run!(j)
    @test something(getresult(j)).thrown isa ErrorException
    struct MyNonExceptionError
        msg::String
    end
    k = Job(() -> throw(MyNonExceptionError("an error occurred!")))
    run!(k)
    @test something(getresult(k)).thrown isa MyNonExceptionError
end
