using SimpleWorkflows: SUCCEEDED, Workflow, run!, getstatus, getresult, →, @job

@testset "Test running a `Workflow`" begin
    i = @job (println("Start job `i`!"); sleep(5)) user = "me" desc = "i"
    j = @job (println("Start job `j`!"); sleep(3); exp(2)) user = "me" desc = "j"
    k = @job (println("Start job `k`!"); sleep(6)) desc = "k"
    l = @job (println("Start job `l`!"); run(`sleep 3`)) desc = "l" user = "me"
    m = @job (println("Start job `m`!"); sleep(3); sin(1)) desc = "m"
    n = @job (println("Start job `n`!"); run(`pwd` & `ls`)) user = "me" desc = "n"
    i → l
    j → k → m → n
    j → l
    k → n
    wf = Workflow(k)
    # @test w.jobs == Workflow(k, j, l, n, m).jobs == Workflow(k, l, m, n, j).jobs
    run!(wf; δt = 0, n = 1)
    @test all(==(SUCCEEDED), getstatus(wf))
    @test something(getresult(i)) === nothing
    @test something(getresult(j)) == 7.38905609893065
    @test something(getresult(k)) === nothing
    @test something(getresult(l)) isa Base.Process
    @test something(getresult(m)) == 0.8414709848078965
    @test something(getresult(n)) isa Base.ProcessChain
end
