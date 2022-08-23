using SimpleWorkflows
using Test

@testset "SimpleWorkflow.jl" begin
    include("job.jl")
    include("workflow.jl")
end
