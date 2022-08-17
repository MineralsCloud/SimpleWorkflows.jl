using SimpleWorkflows.Jobs: SUCCEEDED, Job, run!, getstatus, getresult
using SimpleWorkflows.Workflows: Workflow, SavedWorkflow, →
using SimpleWorkflows.Thunks: Thunk

@testset "Test running a `Workflow`" begin
    function f₁()
        println("Start job `i`!")
        sleep(5)
    end
    function f₂(n)
        println("Start job `j`!")
        sleep(n)
        exp(2)
    end
    function f₃(n)
        println("Start job `k`!")
        sleep(n)
    end
    function f₄()
        println("Start job `l`!")
        run(`sleep 3`)
    end
    function f₅(n, x)
        println("Start job `m`!")
        sleep(n)
        sin(x)
    end
    function f₆(n; x = 1)
        println("Start job `n`!")
        sleep(n)
        cos(x)
        run(`pwd` & `ls`)
    end
    i = Job(Thunk(f₁, ()); user = "me", desc = "i")
    j = Job(Thunk(f₂, 3); user = "he", desc = "j")
    k = Job(Thunk(f₃, 6); desc = "k")
    l = Job(Thunk(f₄, ()); desc = "l", user = "me")
    m = Job(Thunk(f₅, 3, 1); desc = "m")
    n = Job(Thunk(f₆, 1; x = 3); user = "she", desc = "n")
    i → l
    j → k → m → n
    j → l
    k → n
    wf = Workflow(k)
    # @test w.jobs == Workflow(k, j, l, n, m).jobs == Workflow(k, l, m, n, j).jobs
    @testset "Test running a `SavedWorkflow`" begin
        swf = SavedWorkflow(wf, "saved.jld2")
        run!(swf; δt = 0, n = 1)
        @test all(==(SUCCEEDED), getstatus(wf))
        @test something(getresult(i)) === nothing
        @test something(getresult(j)) == 7.38905609893065
        @test something(getresult(k)) === nothing
        @test something(getresult(l)) isa Base.Process
        @test something(getresult(m)) == 0.8414709848078965
        @test something(getresult(n)) isa Base.ProcessChain
    end
end

@testset "Test association rules of operators" begin
    @test Meta.parse("a → b ⇉ c → d ⭃ e → f → g → h ⇉ i → j ⭃ k → l → m") ==
          :(a → (b ⇉ (c → (d ⭃ (e → (f → (g → (h ⇉ (i → (j ⭃ (k → (l → m))))))))))))
    @test Meta.parse("x ⇉ ys ⭃ z") == :(x ⇉ (ys ⭃ z))
end
