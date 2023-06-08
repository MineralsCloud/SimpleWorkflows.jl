using SimpleWorkflows
using Test

@testset "SimpleWorkflow.jl" begin
    include("operations.jl")
    include("run.jl")
end
