@testset "Test joining two `Workflow`s" begin
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
    i → j
    i → k
    j → k
    l → m
    l → n
    m → n
    wf₁ = Workflow(k)
    wf₂ = Workflow(n)
    wf₁ → wf₂
    wf = Workflow(k)
    run!(wf)
end