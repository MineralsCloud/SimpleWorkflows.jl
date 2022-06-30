using SimpleWorkflows

j = @job (println("Start job `j`!"); run(`ls`)) user = "me" desc = "j"
k = @job (println("Start job `k`!"); sleep(5)) desc = "k"
l = @job (println("Start job `l`!"); run(`sleep 3`)) desc = "l" user = "me"
m = @job (println("Start job `m`!"); sin(1)) desc = "m"
n = @job (println("Start job `n`!"); run(`pwd` & `ls`)) user = "me" desc = "n"
j ▷ k ▷ n ▷ m
j ▷ l
k ▷ m
w = Workflow(k)
# @test w.jobs == Workflow(k, j, l, n, m).jobs == Workflow(k, l, m, n, j).jobs
run!(w; nap_job = 1, nap = 0, attempts = 1)
@test something(getresult(j)) isa Base.Process
@test something(getresult(k)) === nothing
@test something(getresult(l)) isa Base.Process
@test something(getresult(m)) == 0.8414709848078965
@test something(getresult(n)) isa Base.ProcessChain
