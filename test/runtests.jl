using SimpleWorkflows
using Test

@testset "SimpleWorkflow.jl" begin
    include("run.jl")
    include("operations.jl")
end
