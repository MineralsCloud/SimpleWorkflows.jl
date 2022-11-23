using EasyJobsBase.Thunks: Thunk
using EasyJobsBase: SUCCEEDED, SimpleJob, run!, getstatus, getresult, →
using SimpleWorkflows: Workflow, AutosaveWorkflow

@testset "Test running a `Workflow`" begin
    function f₁()
        println("Start job `i`!")
        return sleep(5)
    end
    function f₂(n)
        println("Start job `j`!")
        sleep(n)
        return exp(2)
    end
    function f₃(n)
        println("Start job `k`!")
        return sleep(n)
    end
    function f₄()
        println("Start job `l`!")
        return run(`sleep 3`)
    end
    function f₅(n, x)
        println("Start job `m`!")
        sleep(n)
        return sin(x)
    end
    function f₆(n; x=1)
        println("Start job `n`!")
        sleep(n)
        cos(x)
        return run(`pwd` & `ls`)
    end
    i = SimpleJob(Thunk(f₁, ()); username="me", name="i")
    j = SimpleJob(Thunk(f₂, 3); username="he", name="j")
    k = SimpleJob(Thunk(f₃, 6); name="k")
    l = SimpleJob(Thunk(f₄, ()); name="l", username="me")
    m = SimpleJob(Thunk(f₅, 3, 1); name="m")
    n = SimpleJob(Thunk(f₆, 1; x=3); username="she", name="n")
    i → l
    j → k → m → n
    j → l
    k → n
    wf = Workflow(k)
    # @test w.jobs == Workflow(k, j, l, n, m).jobs == Workflow(k, l, m, n, j).jobs
    @testset "Test running a `SavedWorkflow`" begin
        swf = SavedWorkflow(wf, "saved.jls")
        run!(swf; δt=0, n=1)
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
