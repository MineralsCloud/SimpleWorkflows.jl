using EasyJobsBase: SUCCEEDED, Job, StronglyDependentJob, run!, liststatus, getresult, →
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
    i = Job(Thunk(f₁); username="me", name="i")
    j = Job(Thunk(f₂, 3); username="he", name="j")
    k = Job(Thunk(f₃, 6); name="k")
    l = Job(Thunk(f₄); name="l", username="me")
    m = Job(Thunk(f₅, 3, 1); name="m")
    n = Job(Thunk(f₆, 1; x=3); username="she", name="n")
    i → l
    j → k → m → n
    j → l
    k → n
    wf = Workflow(k)
    # @test w.jobs == Workflow(k, j, l, n, m).jobs == Workflow(k, l, m, n, j).jobs
    @testset "Test running a `AutosaveWorkflow`" begin
        wf = AutosaveWorkflow("saved.jls", wf)
        run!(wf; δt=0, n=1)
        @test all(==(SUCCEEDED), getstatus(wf))
        @test something(getresult(i)) === nothing
        @test something(getresult(j)) == 7.38905609893065
        @test something(getresult(k)) === nothing
        @test something(getresult(l)) isa Base.Process
        @test something(getresult(m)) == 0.8414709848078965
        @test something(getresult(n)) isa Base.ProcessChain
    end
end

@testset "Test running a `Workflow` with `DependentJob`s" begin
    f₁(x) = write("file", string(x))
    f₂() = read("file", String)
    f₃() = rm("file")
    i = Job(Thunk(f₁, 1001); username="me", name="i")
    j = DependentJob(Thunk(f₂); username="he", name="j")
    k = DependentJob(Thunk(f₃); username="she", name="k")
    i ↠ j ↠ k
    wf = Workflow(k)
    run!(wf)
    @test all(==(SUCCEEDED), getstatus(wf))
    @test getresult(j) == Some("1001")
end

@testset "Test running a `Workflow` with `StronglyDependentJob`s" begin
    f₁(x) = x^2
    f₂(y) = y + 1
    f₃(z) = z / 2
    i = Job(Thunk(f₁, 5); username="me", name="i")
    j = StronglyDependentJob(Thunk(f₂, 3); username="he", name="j")
    k = StronglyDependentJob(Thunk(f₃, 6); username="she", name="k")
    i → j → k
    wf = Workflow(k)
    run!(wf)
    @test all(==(SUCCEEDED), liststatus(wf))
    @test getresult(i) == Some(25)
    @test getresult(j) == Some(26)
    @test getresult(k) == Some(13.0)
end

@testset "Test running a `Workflow` with a `StronglyDependentJob` with more than one parent" begin
    f₁(x) = x^2
    f₂(y) = y + 1
    f₃(z) = z / 2
    f₄(iter) = sum(iter)
    i = Job(Thunk(f₁, 5); username="me", name="i")
    j = Job(Thunk(f₂, 3); username="he", name="j")
    k = Job(Thunk(f₃, 6); username="she", name="k")
    l = StronglyDependentJob(Thunk(f₄, ()); username="she", name="me")
    for job in (i, j, k)
        job → l
    end
    wf = Workflow(k)
    run!(wf)
    @test all(==(SUCCEEDED), liststatus(wf))
    @test getresult(i) == Some(25)
    @test getresult(j) == Some(4)
    @test getresult(k) == Some(3.0)
    @test getresult(l) == Some(32.0)
end
