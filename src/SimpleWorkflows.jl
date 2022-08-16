module SimpleWorkflows

function run! end

include("Thunks.jl")
include("Jobs/Jobs.jl")
include("Workflows/Workflows.jl")

end
