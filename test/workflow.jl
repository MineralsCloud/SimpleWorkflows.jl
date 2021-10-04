using LegibleLambdas: @λ
using SimpleWorkflows

j = AtomicJob(`ls`)
k = AtomicJob(() -> sleep(5); desc = "Sleep for 5 seconds")
l = AtomicJob(`sleep 3`; desc = "Sleep for 3 seconds")
m = AtomicJob(@λ(() -> sin(1)))
n = AtomicJob(`pwd` & `sleep 3`)
j ▷ l ▷ k ▷ n ▷ m
j ▷ k
k ▷ m
w = Workflow(l, k, j, m, n)
@test w.jobs == Workflow(k, j, l, n, m).jobs == Workflow(k, l, m, n, j).jobs
run!(w)
