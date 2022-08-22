using SimpleWorkflows
using Test

@testset "SimpleWorkflow.jl" begin
    include("Thunks.jl")
    include("workflow.jl")
end
