using Thinkers: Thunk
using EasyJobsBase: SUCCEEDED, Job, ConditionalJob, ArgDependentJob, run!, getresult, →

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
    @test Set(wf.jobs) == Set([i, k, j, l, n, m])
    run!(wf)
    @test Set(wf.jobs) == Set([i, k, j, l, n, m])  # Test they are still the same
    @test all(==(SUCCEEDED), liststatus(wf))
    @test something(getresult(i)) === nothing
    @test something(getresult(j)) == 7.38905609893065
    @test something(getresult(k)) === nothing
    @test something(getresult(l)) isa Base.Process
    @test something(getresult(m)) == 0.8414709848078965
    @test something(getresult(n)) isa Base.ProcessChain
end

@testset "Test running a `Workflow` with `ConditionalJob`s" begin
    f₁(x) = write("file", string(x))
    f₂() = read("file", String)
    h = Job(Thunk(sleep, 3); username="me", name="h")
    i = Job(Thunk(f₁, 1001); username="me", name="i")
    j = ConditionalJob(Thunk(map, f₂); username="he", name="j")
    [h, i] .→ Ref(j)
    wf = Workflow(j)
    run!(wf)
    @test all(==(SUCCEEDED), liststatus(wf))
    @test getresult(j) == Some("1001")
end

@testset "Test running a `Workflow` with `ArgDependentJob`s" begin
    f₁(x) = x^2
    f₂(y) = y + 1
    f₃(z) = z / 2
    i = Job(Thunk(f₁, 5); username="me", name="i")
    j = ArgDependentJob(Thunk(f₂, 3); username="he", name="j")
    k = ArgDependentJob(Thunk(f₃, 6); username="she", name="k")
    i → j → k
    wf = Workflow(k)
    run!(wf)
    @test all(==(SUCCEEDED), liststatus(wf))
    @test getresult(i) == Some(25)
    @test getresult(j) == Some(26)
    @test getresult(k) == Some(13.0)
end

@testset "Test running a `Workflow` with a `ArgDependentJob` with more than one parent" begin
    f₁(x) = x^2
    f₂(y) = y + 1
    f₃(z) = z / 2
    f₄(iter) = sum(iter)
    i = Job(Thunk(f₁, 5); username="me", name="i")
    j = Job(Thunk(f₂, 3); username="he", name="j")
    k = Job(Thunk(f₃, 6); username="she", name="k")
    l = ArgDependentJob(Thunk(f₄, ()); username="she", name="me")
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
