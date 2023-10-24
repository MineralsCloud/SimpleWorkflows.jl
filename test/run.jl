using Thinkers: Thunk
using EasyJobsBase: Job, ConditionalJob, ArgDependentJob, run!, getresult, →

@testset "Test running a `Workflow`" begin
    function f₁()
        println("Start job `i`!")
        sleep(5)
        println("End job `i`!")
        return nothing
    end
    function f₂(n)
        println("Start job `j`!")
        sleep(n)
        a = exp(2)
        println("End job `j`!")
        return a
    end
    function f₃(n)
        println("Start job `k`!")
        sleep(n)
        println("End job `k`!")
        return nothing
    end
    function f₄()
        println("Start job `l`!")
        p = run(`sleep 3`)
        println("End job `l`!")
        return p
    end
    function f₅(n, x)
        println("Start job `m`!")
        sleep(n)
        a = sin(x)
        println("End job `m`!")
        return a
    end
    function f₆(n; x=1)
        println("Start job `n`!")
        sleep(n)
        p = run(`pwd` & `ls`)
        println("End job `n`!")
        return p
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
    run!(wf; wait=true)
    @test Set(wf.jobs) == Set([i, k, j, l, n, m])  # Test they are still the same
    for job in (i, j, k, l, n, m)
        @test job in wf
    end
    @test issucceeded(wf)
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
    run!(wf; wait=true)
    @test issucceeded(wf)
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
    @test indexin([i, j, k], wf) == 1:3
    run!(wf; wait=true)
    for job in (i, j, k)
        @test job in wf
    end
    @test issucceeded(wf)
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
    run!(wf; wait=true)
    for job in (i, j, k)
        @test job in wf
    end
    @test issucceeded(wf)
    @test getresult(i) == Some(25)
    @test getresult(j) == Some(4)
    @test getresult(k) == Some(3.0)
    @test getresult(l) == Some(32.0)
end
