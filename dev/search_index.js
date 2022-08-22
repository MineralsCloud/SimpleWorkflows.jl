var documenterSearchIndex = {"docs":
[{"location":"contributing/#contributing","page":"Contributing","title":"Contributing","text":"","category":"section"},{"location":"contributing/","page":"Contributing","title":"Contributing","text":"Pages = [\"contributing.md\"]","category":"page"},{"location":"contributing/#Download-the-project","page":"Contributing","title":"Download the project","text":"","category":"section"},{"location":"contributing/","page":"Contributing","title":"Contributing","text":"Similar to installation, run","category":"page"},{"location":"contributing/","page":"Contributing","title":"Contributing","text":"using Pkg\nPkg.update()\npkg\"dev SimpleWorkflows\"","category":"page"},{"location":"contributing/","page":"Contributing","title":"Contributing","text":"in the REPL.","category":"page"},{"location":"contributing/","page":"Contributing","title":"Contributing","text":"Then the package will be cloned to your local machine at a path. On macOS, by default is located at ~/.julia/dev/SimpleWorkflows unless you modify the JULIA_DEPOT_PATH environment variable. (See Julia's official documentation on how to do this.) In the following text, we will call it PKGROOT.","category":"page"},{"location":"contributing/#instantiating","page":"Contributing","title":"Instantiate the project","text":"","category":"section"},{"location":"contributing/","page":"Contributing","title":"Contributing","text":"Go to PKGROOT, start a new Julia session and run","category":"page"},{"location":"contributing/","page":"Contributing","title":"Contributing","text":"using Pkg\nPkg.instantiate()","category":"page"},{"location":"contributing/#How-to-build-docs","page":"Contributing","title":"How to build docs","text":"","category":"section"},{"location":"contributing/","page":"Contributing","title":"Contributing","text":"Usually, the up-to-state doc is available in here, but there are cases where users need to build the doc themselves.","category":"page"},{"location":"contributing/","page":"Contributing","title":"Contributing","text":"After instantiating the project, go to PKGROOT, run","category":"page"},{"location":"contributing/","page":"Contributing","title":"Contributing","text":"julia --color=yes docs/make.jl","category":"page"},{"location":"contributing/","page":"Contributing","title":"Contributing","text":"in your terminal. In a while a folder PKGROOT/docs/build will appear. Open PKGROOT/docs/build/index.html with your favorite browser and have fun!","category":"page"},{"location":"contributing/#How-to-run-tests","page":"Contributing","title":"How to run tests","text":"","category":"section"},{"location":"contributing/","page":"Contributing","title":"Contributing","text":"After instantiating the project, go to PKGROOT, run","category":"page"},{"location":"contributing/","page":"Contributing","title":"Contributing","text":"julia --color=yes test/runtests.jl","category":"page"},{"location":"contributing/","page":"Contributing","title":"Contributing","text":"in your terminal.","category":"page"},{"location":"contributing/#Style-Guide","page":"Contributing","title":"Style Guide","text":"","category":"section"},{"location":"contributing/","page":"Contributing","title":"Contributing","text":"Follow the style of the surrounding text when making changes. When adding new features please try to stick to the following points whenever applicable.","category":"page"},{"location":"contributing/#Julia","page":"Contributing","title":"Julia","text":"","category":"section"},{"location":"contributing/","page":"Contributing","title":"Contributing","text":"4-space indentation;\nmodules spanning entire files should not be indented, but modules that have surrounding code should;\ndo not manually align syntax such as = or :: over adjacent lines;\nuse function ... end when a method definition contains more than one top-level expression;\nrelated short-form method definitions don't need a new line between them;\nunrelated or long-form method definitions must have a blank line separating each one;\nsurround all binary operators with whitespace except for ::, ^, and :;\nfiles containing a single module ... end must be named after the module;\nmethod arguments should be ordered based on the amount of usage within the method body;\nmethods extended from other modules must follow their inherited argument order, not the above rule;\nexplicit return should be preferred except in short-form method definitions;\navoid dense expressions where possible e.g. prefer nested ifs over complex nested ?s;\ninclude a trailing , in vectors, tuples, or method calls that span several lines;\ndo not use multiline comments (#= and =#);\nwrap long lines as near to 92 characters as possible, this includes docstrings;\nfollow the standard naming conventions used in Base.","category":"page"},{"location":"contributing/#Markdown","page":"Contributing","title":"Markdown","text":"","category":"section"},{"location":"contributing/","page":"Contributing","title":"Contributing","text":"Use unbalanced # headers, i.e. no # on the right-hand side of the header text;\ninclude a single blank line between top-level blocks;\ndo not hard wrap lines;\nuse emphasis (*) and bold (**) sparingly;\nalways use fenced code blocks instead of indented blocks;\nfollow the conventions outlined in the Julia documentation page on documentation.","category":"page"},{"location":"public/","page":"Library","title":"Library","text":"CurrentModule = SimpleWorkflows","category":"page"},{"location":"public/#Library","page":"Library","title":"Library","text":"","category":"section"},{"location":"public/","page":"Library","title":"Library","text":"Pages = [\"public.md\"]","category":"page"},{"location":"public/","page":"Library","title":"Library","text":"CurrentModule = SimpleWorkflows.Thunks","category":"page"},{"location":"public/#Thunks-module","page":"Library","title":"Thunks module","text":"","category":"section"},{"location":"public/","page":"Library","title":"Library","text":"Thunk\nreify!\ngetresult(::Thunk)","category":"page"},{"location":"public/#SimpleWorkflows.Thunks.Thunk","page":"Library","title":"SimpleWorkflows.Thunks.Thunk","text":"Thunk(::Function, args::Tuple, kwargs::NamedTuple)\nThunk(::Function, args...; kwargs...)\nThunk(::Function)\n\nHold a Function and its arguments for lazy evaluation. Use reify! to evaluate.\n\nExamples\n\njulia> a = Thunk(x -> 3x, 4);\n\njulia> reify!(a)\nSome(12)\n\njulia> b = Thunk(+, 4, 5);\n\njulia> reify!(b)\nSome(9)\n\njulia> c = Thunk(sleep)(1);\n\njulia> getresult(c)  # `c` has not been evaluated\n\njulia> reify!(c)  # `c` has been evaluated\nSome(nothing)\n\njulia> f(args...; kwargs...) = collect(kwargs);\n\njulia> d = Thunk(f)(1, 2, 3; x=1.0, y=4, z=\"5\");\n\njulia> reify!(d)\nSome(Pair{Symbol, Any}[:x => 1.0, :y => 4, :z => \"5\"])\n\njulia> e = Thunk(sin, \"1\");  # Catch errors\n\njulia> reify!(e);\n\n\n\n\n\n","category":"type"},{"location":"public/#SimpleWorkflows.Thunks.reify!","page":"Library","title":"SimpleWorkflows.Thunks.reify!","text":"reify!(thunk::Thunk)\n\nReify a Thunk into a value.\n\nCompute the value of the expression. Walk through the Thunk's arguments and keywords, recursively evaluating each one, and then evaluating the Thunk's function with the evaluated arguments.\n\nSee also Thunk.\n\n\n\n\n\n","category":"function"},{"location":"public/#SimpleWorkflows.Thunks.getresult-Tuple{SimpleWorkflows.Thunks.Thunk}","page":"Library","title":"SimpleWorkflows.Thunks.getresult","text":"getresult(thunk::Thunk)\n\nGet the result of a Thunk. If thunk has not been evaluated, return nothing, else return a Some-wrapped result.\n\n\n\n\n\n","category":"method"},{"location":"public/","page":"Library","title":"Library","text":"CurrentModule = SimpleWorkflows.Jobs","category":"page"},{"location":"public/#Jobs-module","page":"Library","title":"Jobs module","text":"","category":"section"},{"location":"public/","page":"Library","title":"Library","text":"Job\ngetresult(::Job)\ngetstatus(::Job)\nispending\nisrunning\nisexited\nissucceeded\nisfailed\nisinterrupted\npendingjobs\nrunningjobs\nexitedjobs\nsucceededjobs\nfailedjobs\ninterruptedjobs\ncreatedtime\nstarttime\nstoptime\nelapsed\ndescription\nrun!(::Job)\ninterrupt!\nqueue\nquery\nntimes","category":"page"},{"location":"public/#SimpleWorkflows.Jobs.Job","page":"Library","title":"SimpleWorkflows.Jobs.Job","text":"Job(thunk::Thunk; desc=\"\", user=\"\")\n\nCreate a simple job.\n\nArguments\n\nthunk: a Thunk that encloses the job definition.\ndesc::String=\"\": describe briefly what this job does.\nuser::String=\"\": indicate who executes this job.\n\nExamples\n\njulia> a = Job(Thunk(sleep)(5); user=\"me\", desc=\"Sleep for 5 seconds\");\n\njulia> b = Job(Thunk(run, `pwd` & `ls`); user=\"me\", desc=\"Run some commands\");\n\n\n\n\n\n","category":"type"},{"location":"public/#SimpleWorkflows.Thunks.getresult-Tuple{SimpleWorkflows.Jobs.Job}","page":"Library","title":"SimpleWorkflows.Thunks.getresult","text":"getresult(job::Job)\n\nGet the running result of a Job.\n\nThe result is wrapped by a Some type. Use something to retrieve its value. If it is nothing, the Job is not finished.\n\n\n\n\n\n","category":"method"},{"location":"public/#SimpleWorkflows.Jobs.getstatus-Tuple{SimpleWorkflows.Jobs.Job}","page":"Library","title":"SimpleWorkflows.Jobs.getstatus","text":"getstatus(x::Job)\n\nGet the current status of a Job.\n\n\n\n\n\n","category":"method"},{"location":"public/#SimpleWorkflows.Jobs.ispending","page":"Library","title":"SimpleWorkflows.Jobs.ispending","text":"Test if the Job is still pending.\n\n\n\n\n\n","category":"function"},{"location":"public/#SimpleWorkflows.Jobs.isrunning","page":"Library","title":"SimpleWorkflows.Jobs.isrunning","text":"Test if the Job is running.\n\n\n\n\n\n","category":"function"},{"location":"public/#SimpleWorkflows.Jobs.isexited","page":"Library","title":"SimpleWorkflows.Jobs.isexited","text":"Test if the Job has exited.\n\n\n\n\n\n","category":"function"},{"location":"public/#SimpleWorkflows.Jobs.issucceeded","page":"Library","title":"SimpleWorkflows.Jobs.issucceeded","text":"Test if the Job was successfully run.\n\n\n\n\n\n","category":"function"},{"location":"public/#SimpleWorkflows.Jobs.isfailed","page":"Library","title":"SimpleWorkflows.Jobs.isfailed","text":"Test if the Job failed during running.\n\n\n\n\n\n","category":"function"},{"location":"public/#SimpleWorkflows.Jobs.isinterrupted","page":"Library","title":"SimpleWorkflows.Jobs.isinterrupted","text":"Test if the Job was interrupted during running.\n\n\n\n\n\n","category":"function"},{"location":"public/#SimpleWorkflows.Jobs.pendingjobs","page":"Library","title":"SimpleWorkflows.Jobs.pendingjobs","text":"pendingjobs(jobs)\n\nFilter only the pending jobs in a sequence of Jobs.\n\n\n\n\n\npendingjobs(wf::Workflow)\n\nFilter only the pending jobs in a Workflow.\n\n\n\n\n\n","category":"function"},{"location":"public/#SimpleWorkflows.Jobs.runningjobs","page":"Library","title":"SimpleWorkflows.Jobs.runningjobs","text":"runningjobs(jobs)\n\nFilter only the running jobs in a sequence of Jobs.\n\n\n\n\n\nrunningjobs(wf::Workflow)\n\nFilter only the pending jobs in a Workflow.\n\n\n\n\n\n","category":"function"},{"location":"public/#SimpleWorkflows.Jobs.exitedjobs","page":"Library","title":"SimpleWorkflows.Jobs.exitedjobs","text":"exitedjobs(jobs)\n\nFilter only the exited jobs in a sequence of Jobs.\n\n\n\n\n\nexitedjobs(wf::Workflow)\n\nFilter only the pending jobs in a Workflow.\n\n\n\n\n\n","category":"function"},{"location":"public/#SimpleWorkflows.Jobs.succeededjobs","page":"Library","title":"SimpleWorkflows.Jobs.succeededjobs","text":"succeededjobs(jobs)\n\nFilter only the succeeded jobs in a sequence of Jobs.\n\n\n\n\n\nsucceededjobs(wf::Workflow)\n\nFilter only the pending jobs in a Workflow.\n\n\n\n\n\n","category":"function"},{"location":"public/#SimpleWorkflows.Jobs.failedjobs","page":"Library","title":"SimpleWorkflows.Jobs.failedjobs","text":"failedjobs(jobs)\n\nFilter only the failed jobs in a sequence of Jobs.\n\n\n\n\n\nfailedjobs(wf::Workflow)\n\nFilter only the pending jobs in a Workflow.\n\n\n\n\n\n","category":"function"},{"location":"public/#SimpleWorkflows.Jobs.interruptedjobs","page":"Library","title":"SimpleWorkflows.Jobs.interruptedjobs","text":"interruptedjobs(jobs)\n\nFilter only the interrupted jobs in a sequence of Jobs.\n\n\n\n\n\ninterruptedjobs(wf::Workflow)\n\nFilter only the pending jobs in a Workflow.\n\n\n\n\n\n","category":"function"},{"location":"public/#SimpleWorkflows.Jobs.createdtime","page":"Library","title":"SimpleWorkflows.Jobs.createdtime","text":"Return the created time of a Job.\n\n\n\n\n\n","category":"function"},{"location":"public/#SimpleWorkflows.Jobs.starttime","page":"Library","title":"SimpleWorkflows.Jobs.starttime","text":"starttime(job::Job)\n\nReturn the start time of a Job. Return nothing if it is still pending.\n\n\n\n\n\n","category":"function"},{"location":"public/#SimpleWorkflows.Jobs.stoptime","page":"Library","title":"SimpleWorkflows.Jobs.stoptime","text":"stoptime(job::Job)\n\nReturn the stop time of a Job. Return nothing if it has not exited.\n\n\n\n\n\n","category":"function"},{"location":"public/#SimpleWorkflows.Jobs.elapsed","page":"Library","title":"SimpleWorkflows.Jobs.elapsed","text":"elapsed(job::Job)\n\nReturn the elapsed time of a Job since it started running.\n\nIf nothing, the Job is still pending. If it is finished, return how long it took to complete.\n\n\n\n\n\n","category":"function"},{"location":"public/#SimpleWorkflows.Jobs.description","page":"Library","title":"SimpleWorkflows.Jobs.description","text":"description(job::Job)\n\nReturn the description of a Job.\n\n\n\n\n\n","category":"function"},{"location":"public/#SimpleWorkflows.run!-Tuple{SimpleWorkflows.Jobs.Job}","page":"Library","title":"SimpleWorkflows.run!","text":"run!(job::Job; n=1, δt=1)\n\nRun a Job with maximum n attempts, with each attempt separated by δt seconds.\n\n\n\n\n\n","category":"method"},{"location":"public/#SimpleWorkflows.Jobs.interrupt!","page":"Library","title":"SimpleWorkflows.Jobs.interrupt!","text":"interrupt!(job::Job)\n\nManually interrupt a Job, works only if it is running.\n\n\n\n\n\n","category":"function"},{"location":"public/#SimpleWorkflows.Jobs.queue","page":"Library","title":"SimpleWorkflows.Jobs.queue","text":"queue(; sortby = :created_time)\n\nPrint all Jobs that are pending, running, or finished as a table.\n\nAccpetable arguments for sortby are :created_time, :user, :start_time, :stop_time, :elapsed, :status, and :times.\n\n\n\n\n\n","category":"function"},{"location":"public/#SimpleWorkflows.Jobs.query","page":"Library","title":"SimpleWorkflows.Jobs.query","text":"query(id::Integer)\nquery(ids::AbstractVector{<:Integer})\n\nQuery a specific (or a list of Jobs) by its (theirs) ID.\n\n\n\n\n\n","category":"function"},{"location":"public/#SimpleWorkflows.Jobs.ntimes","page":"Library","title":"SimpleWorkflows.Jobs.ntimes","text":"ntimes(id::Integer)\nntimes(job::Job)\n\nReturn how many times a Job has been rerun.\n\n\n\n\n\n","category":"function"},{"location":"public/","page":"Library","title":"Library","text":"CurrentModule = SimpleWorkflows.Workflows","category":"page"},{"location":"public/#Workflows-module","page":"Library","title":"Workflows module","text":"","category":"section"},{"location":"public/","page":"Library","title":"Library","text":"Workflow\nrun!(::Workflow)\ngetstatus(::Workflow)\nchain\n→\n←\nthread\n⇶\n⬱\nfork\nconverge\nspindle\npendingjobs(::Workflow)\nrunningjobs(::Workflow)\nexitedjobs(::Workflow)\nsucceededjobs(::Workflow)\nfailedjobs(::Workflow)\ninterruptedjobs(::Workflow)","category":"page"},{"location":"public/#SimpleWorkflows.Workflows.Workflow","page":"Library","title":"SimpleWorkflows.Workflows.Workflow","text":"Workflow(jobs, graph)\n\nCreate a Workflow from a list of Jobs and a graph representing their relations.\n\n\n\n\n\n","category":"type"},{"location":"public/#SimpleWorkflows.run!-Tuple{SimpleWorkflows.Workflows.Workflow}","page":"Library","title":"SimpleWorkflows.run!","text":"run!(wf::Workflow; n=5, δt=1, Δt=1)\n\nRun a Workflow with maximum n attempts, with each attempt separated by Δt seconds.\n\nCool down for δt seconds after each Job in the Workflow.\n\n\n\n\n\n","category":"method"},{"location":"public/#SimpleWorkflows.Jobs.getstatus-Tuple{SimpleWorkflows.Workflows.Workflow}","page":"Library","title":"SimpleWorkflows.Jobs.getstatus","text":"getstatus(wf::Workflow)\n\nGet the current status of Jobs in a Workflow.\n\n\n\n\n\n","category":"method"},{"location":"public/#SimpleWorkflows.Workflows.chain","page":"Library","title":"SimpleWorkflows.Workflows.chain","text":"chain(x::Job, y::Job, z::Job...)\n\nChain multiple Jobs one after another.\n\n\n\n\n\n","category":"function"},{"location":"public/#SimpleWorkflows.Workflows.:→","page":"Library","title":"SimpleWorkflows.Workflows.:→","text":"→(x, y)\n\nChain two Jobs.\n\n\n\n\n\n","category":"function"},{"location":"public/#SimpleWorkflows.Workflows.:←","page":"Library","title":"SimpleWorkflows.Workflows.:←","text":"←(y, x)\n\nChain two Jobs reversely.\n\n\n\n\n\n","category":"function"},{"location":"public/#SimpleWorkflows.Workflows.thread","page":"Library","title":"SimpleWorkflows.Workflows.thread","text":"thread(xs::AbstractVector{Job}, ys::AbstractVector{Job}, zs::AbstractVector{Job}...)\n\nChain multiple vectors of Jobs, each Job in xs has a corresponding Job in ys.`\n\n\n\n\n\n","category":"function"},{"location":"public/#SimpleWorkflows.Workflows.:⇶","page":"Library","title":"SimpleWorkflows.Workflows.:⇶","text":"⇶(xs, ys)\n\nChain two vectors of Jobs.\n\n\n\n\n\n","category":"function"},{"location":"public/#SimpleWorkflows.Workflows.:⬱","page":"Library","title":"SimpleWorkflows.Workflows.:⬱","text":"⬱(ys, xs)\n\nChain two vectors of Jobs reversely.\n\n\n\n\n\n","category":"function"},{"location":"public/#SimpleWorkflows.Workflows.fork","page":"Library","title":"SimpleWorkflows.Workflows.fork","text":"fork(x::Job, ys::AbstractVector{Job})\n⇉(x, ys)\n\nAttach a group of parallel Jobs (ys) to a single Job (x).\n\n\n\n\n\n","category":"function"},{"location":"public/#SimpleWorkflows.Workflows.converge","page":"Library","title":"SimpleWorkflows.Workflows.converge","text":"converge(xs::AbstractVector{Job}, y::Job)\n⭃(xs, y)\n\nFinish a group a parallel Jobs (xs) by a single Job (y).\n\n\n\n\n\n","category":"function"},{"location":"public/#SimpleWorkflows.Workflows.spindle","page":"Library","title":"SimpleWorkflows.Workflows.spindle","text":"spindle(x::Job, ys::AbstractVector{Job}, z::Job)\n\nStart from a Job (x), followed by a series of Jobs (ys), finished by a single Job (z).\n\n\n\n\n\n","category":"function"},{"location":"public/#SimpleWorkflows.Jobs.pendingjobs-Tuple{SimpleWorkflows.Workflows.Workflow}","page":"Library","title":"SimpleWorkflows.Jobs.pendingjobs","text":"pendingjobs(wf::Workflow)\n\nFilter only the pending jobs in a Workflow.\n\n\n\n\n\n","category":"method"},{"location":"public/#SimpleWorkflows.Jobs.runningjobs-Tuple{SimpleWorkflows.Workflows.Workflow}","page":"Library","title":"SimpleWorkflows.Jobs.runningjobs","text":"runningjobs(wf::Workflow)\n\nFilter only the pending jobs in a Workflow.\n\n\n\n\n\n","category":"method"},{"location":"public/#SimpleWorkflows.Jobs.exitedjobs-Tuple{SimpleWorkflows.Workflows.Workflow}","page":"Library","title":"SimpleWorkflows.Jobs.exitedjobs","text":"exitedjobs(wf::Workflow)\n\nFilter only the pending jobs in a Workflow.\n\n\n\n\n\n","category":"method"},{"location":"public/#SimpleWorkflows.Jobs.succeededjobs-Tuple{SimpleWorkflows.Workflows.Workflow}","page":"Library","title":"SimpleWorkflows.Jobs.succeededjobs","text":"succeededjobs(wf::Workflow)\n\nFilter only the pending jobs in a Workflow.\n\n\n\n\n\n","category":"method"},{"location":"public/#SimpleWorkflows.Jobs.failedjobs-Tuple{SimpleWorkflows.Workflows.Workflow}","page":"Library","title":"SimpleWorkflows.Jobs.failedjobs","text":"failedjobs(wf::Workflow)\n\nFilter only the pending jobs in a Workflow.\n\n\n\n\n\n","category":"method"},{"location":"public/#SimpleWorkflows.Jobs.interruptedjobs-Tuple{SimpleWorkflows.Workflows.Workflow}","page":"Library","title":"SimpleWorkflows.Jobs.interruptedjobs","text":"interruptedjobs(wf::Workflow)\n\nFilter only the pending jobs in a Workflow.\n\n\n\n\n\n","category":"method"},{"location":"installation/#installation","page":"Installation guide","title":"Installation guide","text":"","category":"section"},{"location":"installation/","page":"Installation guide","title":"Installation guide","text":"Here are the installation instructions for package SimpleWorkflows. If you have trouble installing it, please refer to our Troubleshooting page for more information.","category":"page"},{"location":"installation/#Install-Julia","page":"Installation guide","title":"Install Julia","text":"","category":"section"},{"location":"installation/","page":"Installation guide","title":"Installation guide","text":"First, you should install Julia. We recommend downloading it from its official website. Please follow the detailed instructions on its website if you have to build Julia from source. Some computing centers provide preinstalled Julia. Please contact your administrator for more information in that case. Here's some additional information on how to set up Julia on HPC systems.","category":"page"},{"location":"installation/","page":"Installation guide","title":"Installation guide","text":"If you have Homebrew installed, open Terminal.app and type","category":"page"},{"location":"installation/","page":"Installation guide","title":"Installation guide","text":"brew install --cask julia","category":"page"},{"location":"installation/","page":"Installation guide","title":"Installation guide","text":"if you want to install it as a prebuilt binary app. Type","category":"page"},{"location":"installation/","page":"Installation guide","title":"Installation guide","text":"brew install julia","category":"page"},{"location":"installation/","page":"Installation guide","title":"Installation guide","text":"if you want to install it as a formula.","category":"page"},{"location":"installation/","page":"Installation guide","title":"Installation guide","text":"If you want to install multiple Julia versions in the same operating system, a suggested way is to use a version manager such as asdf. First, install asdf. Then, run","category":"page"},{"location":"installation/","page":"Installation guide","title":"Installation guide","text":"asdf install julia 1.6.6  # or other versions of Julia\nasdf global julia 1.6.6","category":"page"},{"location":"installation/","page":"Installation guide","title":"Installation guide","text":"to install Julia and set v1.6.6 as a global version.","category":"page"},{"location":"installation/","page":"Installation guide","title":"Installation guide","text":"You can also try another cross-platform installer for the Julia programming language juliaup.","category":"page"},{"location":"installation/#Which-version-should-I-pick?","page":"Installation guide","title":"Which version should I pick?","text":"","category":"section"},{"location":"installation/","page":"Installation guide","title":"Installation guide","text":"You can install the \"Current stable release\" or the \"Long-term support (LTS) release\".","category":"page"},{"location":"installation/","page":"Installation guide","title":"Installation guide","text":"The \"Current stable release\" is the latest release of Julia. It has access to newer features, and is likely faster.\nThe \"Long-term support release\" is an older version of Julia that has continued to receive bug and security fixes. However, it may not have the latest features or performance improvements.","category":"page"},{"location":"installation/","page":"Installation guide","title":"Installation guide","text":"For most users, you should install the \"Current stable release\", and whenever Julia releases a new version of the current stable release, you should update your version of Julia. Note that any code you write on one version of the current stable release will continue to work on all subsequent releases.","category":"page"},{"location":"installation/","page":"Installation guide","title":"Installation guide","text":"For users in restricted software environments (e.g., your enterprise IT controls what software you can install), you may be better off installing the long-term support release because you will not have to update Julia as frequently.","category":"page"},{"location":"installation/","page":"Installation guide","title":"Installation guide","text":"Versions higher than v1.3, especially v1.6, are strongly recommended. This package may not work on v1.0 and below. Since the Julia team has set v1.6 as the LTS release, we will gradually drop support for versions below v1.6.","category":"page"},{"location":"installation/","page":"Installation guide","title":"Installation guide","text":"Julia and Julia packages support multiple operating systems and CPU architectures; check this table to see if it can be installed on your machine. For Mac computers with M-series processors, this package and its dependencies may not work. Please install the Intel-compatible version of Julia (for macOS x86).","category":"page"},{"location":"installation/#Install-SimpleWorkflows","page":"Installation guide","title":"Install SimpleWorkflows","text":"","category":"section"},{"location":"installation/","page":"Installation guide","title":"Installation guide","text":"Now I am using macOS as a standard platform to explain the following steps:","category":"page"},{"location":"installation/","page":"Installation guide","title":"Installation guide","text":"Open Terminal.app, and type julia to start an interactive session (known as the REPL).\nRun the following commands and wait for them to finish:\njulia> using Pkg\n\njulia> Pkg.update()\n\njulia> Pkg.add(\"SimpleWorkflows\")\nRun\njulia> using SimpleWorkflows\nand have fun!\nWhile using, please keep this Julia session alive. Restarting might recompile the package and cost some time.","category":"page"},{"location":"installation/","page":"Installation guide","title":"Installation guide","text":"If you want to install the latest in-development (probably buggy) version of SimpleWorkflows, type","category":"page"},{"location":"installation/","page":"Installation guide","title":"Installation guide","text":"using Pkg\nPkg.update()\npkg\"add SimpleWorkflows#master\"","category":"page"},{"location":"installation/","page":"Installation guide","title":"Installation guide","text":"in the second step above.","category":"page"},{"location":"installation/#Update-SimpleWorkflows","page":"Installation guide","title":"Update SimpleWorkflows","text":"","category":"section"},{"location":"installation/","page":"Installation guide","title":"Installation guide","text":"Please watch our GitHub repository for new releases. Once we release a new version, you can update SimpleWorkflows by typing","category":"page"},{"location":"installation/","page":"Installation guide","title":"Installation guide","text":"using Pkg\nPkg.update(\"SimpleWorkflows\")\nPkg.gc()","category":"page"},{"location":"installation/","page":"Installation guide","title":"Installation guide","text":"in Julia REPL.","category":"page"},{"location":"installation/#Uninstall-and-reinstall-SimpleWorkflows","page":"Installation guide","title":"Uninstall and reinstall SimpleWorkflows","text":"","category":"section"},{"location":"installation/","page":"Installation guide","title":"Installation guide","text":"To uninstall, in a Julia session, run\njulia> using Pkg\n\njulia> Pkg.rm(\"SimpleWorkflows\")\n\njulia> Pkg.gc()\nPress ctrl+d to quit the current session. Start a new Julia session and reinstall SimpleWorkflows.","category":"page"},{"location":"troubleshooting/#Troubleshooting","page":"Troubleshooting","title":"Troubleshooting","text":"","category":"section"},{"location":"troubleshooting/","page":"Troubleshooting","title":"Troubleshooting","text":"This page collects some possible errors you may encounter and trick how to fix them.","category":"page"},{"location":"troubleshooting/","page":"Troubleshooting","title":"Troubleshooting","text":"If you have additional tips, please submit a PR with suggestions.","category":"page"},{"location":"troubleshooting/#Installation-problems","page":"Troubleshooting","title":"Installation problems","text":"","category":"section"},{"location":"troubleshooting/#Cannot-find-the-Julia-executable","page":"Troubleshooting","title":"Cannot find the Julia executable","text":"","category":"section"},{"location":"troubleshooting/","page":"Troubleshooting","title":"Troubleshooting","text":"Make sure you have Julia installed in your environment. Please download the latest stable version for your platform. If you are using macOS, the recommended way is to use Homebrew. If you do not want to install Homebrew or you are using other platforms that Julia supports, download the corresponding binaries. And then create a symbolic link /usr/local/bin/julia to the Julia executable. If /usr/local/bin/ is not in your $PATH, export it to your $PATH. Some clusters, like Habanero, Comet, or Expanse, already have Julia installed as a module, you may just module load julia to use it. If not, either install by yourself or contact your administrator.","category":"page"},{"location":"troubleshooting/#Loading-SimpleWorkflows","page":"Troubleshooting","title":"Loading SimpleWorkflows","text":"","category":"section"},{"location":"troubleshooting/#Why-is-Julia-compiling/loading-modules-so-slow?-What-can-I-do?","page":"Troubleshooting","title":"Why is Julia compiling/loading modules so slow? What can I do?","text":"","category":"section"},{"location":"troubleshooting/","page":"Troubleshooting","title":"Troubleshooting","text":"First, we recommend you download the latest version of Julia. Usually, the newest version has the best performance.","category":"page"},{"location":"troubleshooting/","page":"Troubleshooting","title":"Troubleshooting","text":"If you just want Julia to do a simple task and only once, you could start Julia REPL with","category":"page"},{"location":"troubleshooting/","page":"Troubleshooting","title":"Troubleshooting","text":"julia --compile=min","category":"page"},{"location":"troubleshooting/","page":"Troubleshooting","title":"Troubleshooting","text":"to minimize compilation or","category":"page"},{"location":"troubleshooting/","page":"Troubleshooting","title":"Troubleshooting","text":"julia --optimize=0","category":"page"},{"location":"troubleshooting/","page":"Troubleshooting","title":"Troubleshooting","text":"to minimize optimizations, or just use both. Or you could make a system image and run with","category":"page"},{"location":"troubleshooting/","page":"Troubleshooting","title":"Troubleshooting","text":"julia --sysimage custom-image.so","category":"page"},{"location":"troubleshooting/","page":"Troubleshooting","title":"Troubleshooting","text":"See Fredrik Ekre's talk for details.","category":"page"},{"location":"","page":"Home","title":"Home","text":"CurrentModule = SimpleWorkflows","category":"page"},{"location":"#SimpleWorkflows","page":"Home","title":"SimpleWorkflows","text":"","category":"section"},{"location":"","page":"Home","title":"Home","text":"Documentation for SimpleWorkflows.","category":"page"},{"location":"","page":"Home","title":"Home","text":"Build workflows from atomic jobs. Run and monitor them.","category":"page"},{"location":"","page":"Home","title":"Home","text":"This package take inspiration from JobSchedulers.jl and Dispatcher.jl (unmaintained).","category":"page"},{"location":"","page":"Home","title":"Home","text":"Please cite this package as:","category":"page"},{"location":"","page":"Home","title":"Home","text":"@misc{zhang2021textttexpress,\n      title={$\\texttt{express}$: extensible, high-level workflows for swifter $\\textit{ab initio}$ materials modeling},\n      author={Qi Zhang and Chaoxuan Gu and Jingyi Zhuang and Renata M. Wentzcovitch},\n      year={2021},\n      eprint={2109.11724},\n      archivePrefix={arXiv},\n      primaryClass={physics.comp-ph}\n}","category":"page"},{"location":"#Installation","page":"Home","title":"Installation","text":"","category":"section"},{"location":"","page":"Home","title":"Home","text":"The package can be installed with the Julia package manager. From the Julia REPL, type ] to enter the Pkg REPL mode and run:","category":"page"},{"location":"","page":"Home","title":"Home","text":"pkg> add SimpleWorkflows","category":"page"},{"location":"","page":"Home","title":"Home","text":"Or, equivalently, via the Pkg API:","category":"page"},{"location":"","page":"Home","title":"Home","text":"julia> import Pkg; Pkg.add(\"SimpleWorkflows\")","category":"page"},{"location":"#Documentation","page":"Home","title":"Documentation","text":"","category":"section"},{"location":"","page":"Home","title":"Home","text":"STABLE &mdash; documentation of the most recently tagged version.\nDEV &mdash; documentation of the in-development version.","category":"page"},{"location":"#Project-Status","page":"Home","title":"Project Status","text":"","category":"section"},{"location":"","page":"Home","title":"Home","text":"The package is tested against, and being developed for, Julia 1.6 and above on Linux, macOS, and Windows.","category":"page"},{"location":"#Questions-and-Contributions","page":"Home","title":"Questions and Contributions","text":"","category":"section"},{"location":"","page":"Home","title":"Home","text":"Usage questions can be posted on our discussion page.","category":"page"},{"location":"","page":"Home","title":"Home","text":"Contributions are very welcome, as are feature requests and suggestions. Please open an issue if you encounter any problems. The contributing page has a few guidelines that should be followed when opening pull requests and contributing code.","category":"page"},{"location":"#Manual-Outline","page":"Home","title":"Manual Outline","text":"","category":"section"},{"location":"","page":"Home","title":"Home","text":"Pages = [\n    \"installation.md\",\n    \"contributing.md\",\n    \"troubleshooting.md\",\n]\nDepth = 3","category":"page"},{"location":"#Library-Outline","page":"Home","title":"Library Outline","text":"","category":"section"},{"location":"","page":"Home","title":"Home","text":"Pages = [\"public.md\"]","category":"page"},{"location":"#main-index","page":"Home","title":"Index","text":"","category":"section"},{"location":"","page":"Home","title":"Home","text":"Pages = [\"public.md\"]","category":"page"}]
}
