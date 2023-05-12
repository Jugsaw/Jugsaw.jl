var documenterSearchIndex = {"docs":
[{"location":"get-started/#Get-started","page":"Get Started","title":"Get started","text":"","category":"section"},{"location":"get-started/","page":"Get Started","title":"Get Started","text":"(Image: )","category":"page"},{"location":"get-started/","page":"Get Started","title":"Get Started","text":"Developers can register a Jugsaw app on the Jugsaw website.\nUsers (including the developer) can use Jugsaw intances for launching applications on an endpoint.\nA shared Jugsaw instance will be created automatically at the first launch of an app.","category":"page"},{"location":"get-started/#Terms-explained","page":"Get Started","title":"Terms explained","text":"","category":"section"},{"location":"get-started/","page":"Get Started","title":"Get Started","text":"The Jugsaw Website is https://www.jugsaw.co.\nA Jugsaw App is a set of funciton registered on the Jugsaw website.\nAn instance is a living or hibernated container running a Julia session (it may or may not tied to a specific app, which I am not sure).","category":"page"},{"location":"get-started/","page":"Get Started","title":"Get Started","text":"The wake up time of a hibernated container is under 0.5s (goal).","category":"page"},{"location":"get-started/","page":"Get Started","title":"Get Started","text":"An endpoint is the URI of a computational resource vendor, which can be a localhost, a shared EC2 or a cluster.","category":"page"},{"location":"get-started/#Deploy-a-Jugsaw-App","page":"Get Started","title":"Deploy a Jugsaw App","text":"","category":"section"},{"location":"get-started/","page":"Get Started","title":"Get Started","text":"To deploy a Jugsaw app, you must have a Jugsaw account. One may get a free account from https://www.jugsaw.co. To setup a new Jugsaw App, a Julia developer should go through the following process","category":"page"},{"location":"get-started/","page":"Get Started","title":"Get Started","text":"1: Create a Jugsaw App in any folder of a Github repository.","category":"page"},{"location":"get-started/","page":"Get Started","title":"Get Started","text":"julia> using Jugsaw\n\njulia> Jugsaw.Template.init(:Test)\n[ Info: Generated Jugsaw app \"hello-world\" at folder: \"jugsaw\"\n\njulia> readdir(\"jugsaw\")\n5-element Vector{String}:\n \".gitignore\"     #\n \"Project.toml\"   # environment specific cation\n \"app.jl\"         # functions and tests\n \"config.yaml\"    # jugsaw app setting\n \"manager.jl\"     # deployment manager","category":"page"},{"location":"get-started/","page":"Get Started","title":"Get Started","text":"Edit the generated template project.\nRegister your Jugsaw App.\nGo to https://www.jugsaw.co/apps.\nClick \"Create a new Jugsaw App\".\nEnter the Github repo and the subfolder containing your Jugsaw App.","category":"page"},{"location":"get-started/","page":"Get Started","title":"Get Started","text":"<details>   <summary>Alternative: using Github Actions</summary> You should add your Jugsaw deploy key to your repository secrets. A Jugsaw deploy key can be obtained from the Jugsaw website -> Profile -> Deploy Key.","category":"page"},{"location":"get-started/","page":"Get Started","title":"Get Started","text":"To set up repository secrets for GitHub action, follow the steps below:","category":"page"},{"location":"get-started/","page":"Get Started","title":"Get Started","text":"Go to the GitHub repository where you want to set up the secrets.\nClick on the \"Settings\" tab.\nClick on the \"Secrets\" option.\nClick on the \"New repository secret\" button.\nEnter the name of the secret in the \"Name\" field as \"JUGSAWDEPLOYKEY\".\nEnter the value of the secret in the \"Value\" field.\nClick on the \"Add secret\" button.","category":"page"},{"location":"get-started/","page":"Get Started","title":"Get Started","text":"In your GitHub action workflow file, reference the secrets using the syntax {{secrets.SECRET_NAME}}.","category":"page"},{"location":"get-started/","page":"Get Started","title":"Get Started","text":"Note: It's important to keep your secrets secure and not include them in your code or make them publicly available. </details>","category":"page"},{"location":"get-started/#Run-a-Jugsaw-App","page":"Get Started","title":"Run a Jugsaw App","text":"","category":"section"},{"location":"get-started/#Using-shared-nodes","page":"Get Started","title":"Using shared nodes","text":"","category":"section"},{"location":"get-started/","page":"Get Started","title":"Get Started","text":"The following is an example of launching a Jugsaw app on the shared endpoint with the Julia language (we have multiple clients).","category":"page"},{"location":"get-started/","page":"Get Started","title":"Get Started","text":"julia> using JugsawClient\n\njulia> msg = open(JugsawClient.SharedNode(\n                endpoint=\"https://api.jugsaw.co\"),\n                app=\"hello-world\",\n                uuid=\"79dccd12-cad8-11ed-387a-f9e5b0f14a94\",\n                keep=true) do app\n        app.greet(\"World\")\n    end;\n\njulia> println(msg[\"result\"]) # the result\nHello World!\n\njulia> println(msg[\"uuid\"])   # the instance id\n\"79dccd12-cad8-11ed-387a-f9e5b0f14a94\"\n\njulia> println(msg[\"time\"])   # time in seconds\n0.001\n\njulia> println(msg[\"exit code\"])   # exit code\n0","category":"page"},{"location":"get-started/","page":"Get Started","title":"Get Started","text":"Rules","category":"page"},{"location":"get-started/","page":"Get Started","title":"Get Started","text":"If uuid is not specified, then the function will be executed on the shared instance (if any).\nIf uuid is specified, then the specific instance will be used (may throw InstanceNotExistError).\nUnless keep is true, an instance will be killed after being inactive for 20min.","category":"page"},{"location":"get-started/","page":"Get Started","title":"Get Started","text":"A free tier user can keep at most 10 instances at the same time. Please go to the control panel to free some instances if you see a InstanceQuotaError or subscribe our Jugsaw premium.","category":"page"},{"location":"get-started/#Using-cluster-nodes","page":"Get Started","title":"Using cluster nodes","text":"","category":"section"},{"location":"get-started/","page":"Get Started","title":"Get Started","text":"The following is an example of launching a Jugsaw app on a cluster with Julia language (we have multiple clients).","category":"page"},{"location":"get-started/","page":"Get Started","title":"Get Started","text":"julia> using JugsawClient\n\njulia> msg = open(JugsawClient.ClusterNode(\n                endpoint=\"https://api.hkust-cluster.edu.cn\"),\n                app=\"hello-world\",\n                ncpu = 5,\n                ngpu = 1,\n                usempi = false,\n                usecuda = true,\n                timelimit = 3600,   # in seconds\n                ) do app\n        app.greet(\"World\")\n    end;\n[ Info: You can manage your job with this URI: https://api.hkust-cluster.edu.cn/monitor/79dccd12-cad8-11ed-387a-f9e5b0f14a94/\n\njulia> println(msg[\"exit code\"])   # exit code\n0","category":"page"},{"location":"get-started/","page":"Get Started","title":"Get Started","text":"Rules","category":"page"},{"location":"get-started/","page":"Get Started","title":"Get Started","text":"Cluster Jugsaw call is stateless.\nThere might be an overhead in using clusters. Cluster pull the reqested app from jugsaw.co to local, create a singularity instance, and launch the job.\nThe result is not returned directly, instead, one should use the returned URI to access the result and manage the jobs.","category":"page"},{"location":"client/#Jugsaw-Client-(Julia)","page":"Jugsaw Client (Julia)","title":"Jugsaw Client (Julia)","text":"","category":"section"},{"location":"client/","page":"Jugsaw Client (Julia)","title":"Jugsaw Client (Julia)","text":"Check Python and Javascript versions.","category":"page"},{"location":"client/","page":"Jugsaw Client (Julia)","title":"Jugsaw Client (Julia)","text":"Jugsaw's Julia client, or Jugsaw.Client, is a submodule of the Julia package Jugsaw. To install Jugsaw, please open Julia's interactive session (known as REPL) and type the following command","category":"page"},{"location":"client/","page":"Jugsaw Client (Julia)","title":"Jugsaw Client (Julia)","text":"julia> using Pkg; Pkg.add(\"Jugsaw\")","category":"page"},{"location":"client/#Tutorial","page":"Jugsaw Client (Julia)","title":"Tutorial","text":"","category":"section"},{"location":"client/","page":"Jugsaw Client (Julia)","title":"Jugsaw Client (Julia)","text":"As a first step, you need to decide which remote to execute a function. By default, it uses the Jugsaw Cloud.","category":"page"},{"location":"client/","page":"Jugsaw Client (Julia)","title":"Jugsaw Client (Julia)","text":"remote = ","category":"page"},{"location":"client/#Advanced-features","page":"Jugsaw Client (Julia)","title":"Advanced features","text":"","category":"section"},{"location":"client/","page":"Jugsaw Client (Julia)","title":"Jugsaw Client (Julia)","text":"Advanced features require you to setup your Jugsaw account.","category":"page"},{"location":"man/Jugsaw/","page":"Jugsaw","title":"Jugsaw","text":"DocTestSetup = quote\n    using Jugsaw\nend ","category":"page"},{"location":"man/Jugsaw/#Jugsaw","page":"Jugsaw","title":"Jugsaw","text":"","category":"section"},{"location":"man/Jugsaw/#Chained-function-call","page":"Jugsaw","title":"Chained function call","text":"","category":"section"},{"location":"man/Jugsaw/","page":"Jugsaw","title":"Jugsaw","text":"When Jugsaw server gets a chained function call, like sin(cos(0.5)). The following two tasks will be added to the task queue.","category":"page"},{"location":"man/Jugsaw/","page":"Jugsaw","title":"Jugsaw","text":"Call(cos, (0.5,), (;)) -> id1\nCall(sin, (object_getter(state_store, id1),), (;))","category":"page"},{"location":"man/Jugsaw/","page":"Jugsaw","title":"Jugsaw","text":"where -> points to the id of the returned object in the state_store. The state_store is a dictionary mapping an object id to its value. When querying an object from the state_store, the program waits for the corresponding task to complete.","category":"page"},{"location":"man/Jugsaw/","page":"Jugsaw","title":"Jugsaw","text":"object_getter(id) returns a Call instance with the following definition","category":"page"},{"location":"man/Jugsaw/","page":"Jugsaw","title":"Jugsaw","text":"function object_getter(state_store::StateStore, object_id::String)\n    Call((s, id)->Meta.parse(Base.getindex(s, id)), (state_store, object_id), (;))\nend","category":"page"},{"location":"man/Jugsaw/","page":"Jugsaw","title":"Jugsaw","text":"The nested Call is then executed by the JugsawIR.fevalself with the following steps","category":"page"},{"location":"man/Jugsaw/","page":"Jugsaw","title":"Jugsaw","text":"sin function is triggered,\nwhile rendering the arguments of sin, the object getter(Call) will trigger the state_store[id1],\nwait for the cos function to complete,\nwith the returned object, execute the sin function.","category":"page"},{"location":"man/Jugsaw/#APIs","page":"Jugsaw","title":"APIs","text":"","category":"section"},{"location":"man/Jugsaw/","page":"Jugsaw","title":"Jugsaw","text":"Modules = [Jugsaw]\nOrder = [:function, :macro, :type, :module]","category":"page"},{"location":"man/Jugsaw/#Jugsaw.activate-Tuple{AppRuntime, JugsawADT}","page":"Jugsaw","title":"Jugsaw.activate","text":"Try to activate an actor. If the requested actor does not exist yet, a new one is created based on the registered ActorFactor of actor_type. Note that the actor may be configured to recover from its lastest state snapshot.\n\n\n\n\n\n","category":"method"},{"location":"man/Jugsaw/#Jugsaw.deactivate!-Tuple{AppRuntime, HTTP.Messages.Request}","page":"Jugsaw","title":"Jugsaw.deactivate!","text":"Remove idle actors. Actors may be configure to persistent its current state.\n\n\n\n\n\n","category":"method"},{"location":"man/Jugsaw/#Jugsaw.fetch-Tuple{AppRuntime, HTTP.Messages.Request}","page":"Jugsaw","title":"Jugsaw.fetch","text":"This is just a workaround. In the future, users should fetch results from StateStore directly.\n\n\n\n\n\n","category":"method"},{"location":"man/Jugsaw/#Jugsaw.Actor","page":"Jugsaw","title":"Jugsaw.Actor","text":"Describe current status of an actor.\n\n\n\n\n\n","category":"type"},{"location":"design/#Design","page":"Design","title":"Design","text":"","category":"section"},{"location":"design/","page":"Design","title":"Design","text":"(Image: )","category":"page"},{"location":"design/#Overview","page":"Design","title":"Overview","text":"","category":"section"},{"location":"design/","page":"Design","title":"Design","text":"<!–","category":"page"},{"location":"design/","page":"Design","title":"Design","text":"What Jugsaw is\nWhat we provide\nFor application developers\nBridge the gap between users and developers?\nFor general users\nA world of ready-to-use applications?","category":"page"},{"location":"design/","page":"Design","title":"Design","text":"–>","category":"page"},{"location":"design/#The-Problem-We-Want-to-Solve","page":"Design","title":"The Problem We Want to Solve","text":"","category":"section"},{"location":"design/#A-Common-Case","page":"Design","title":"A Common Case","text":"","category":"section"},{"location":"design/","page":"Design","title":"Design","text":"A typical open source scientific computing problem solving workflow includes","category":"page"},{"location":"design/","page":"Design","title":"Design","text":"A developer releases an open software on Github.\nUsers know his package from the publications, conferences or friends. (*)\nUsers download the open source code from Git or some package management system (e.g. Julia package management system *).\nUser deploy the environment on their local host and test the software, (*)\nSometimes, uses need to learn a new language like Julia (*).\nUser deploy the environment on a cluster/EC2, which typically runs Linux system (*).\nFact: all top 500 clusters run linux system, over 90% EC2 ship linux system (*).\nUser use slurm system to submit serial/multi-threading/MPI/GPU tasks (*).\nDownload the data from the cluster/EC2 to local host for analysing.","category":"page"},{"location":"design/#The-Scope-of-the-Problem-We-Want-to-Solve","page":"Design","title":"The Scope of the Problem We Want to Solve","text":"","category":"section"},{"location":"design/","page":"Design","title":"Design","text":"Domains/Subjects\nProgramming Languages","category":"page"},{"location":"design/#Existing-Solutions","page":"Design","title":"Existing Solutions","text":"","category":"section"},{"location":"design/","page":"Design","title":"Design","text":"TODO: list the pros and cons of each existing solution.","category":"page"},{"location":"design/","page":"Design","title":"Design","text":"PyCall.jl/PythonCall.jl\nHuggingFace\nStipple.jl","category":"page"},{"location":"design/#Proposed-Solution","page":"Design","title":"Proposed Solution","text":"","category":"section"},{"location":"design/#Key-Concepts","page":"Design","title":"Key Concepts","text":"","category":"section"},{"location":"design/#Contributor","page":"Design","title":"Contributor","text":"","category":"section"},{"location":"design/","page":"Design","title":"Design","text":"Contributors are those who are familiar with a specific library. They can develop applications with the help of Jugsaw SDK and deploy them on our app store.","category":"page"},{"location":"design/#User","page":"Design","title":"User","text":"","category":"section"},{"location":"design/","page":"Design","title":"Design","text":"Different from Contributor, general users do not need to understand all the underlying implementation details.","category":"page"},{"location":"design/","page":"Design","title":"Design","text":"For entry level users, they are more interested in interacting with the Applications through the web portal. ","category":"page"},{"location":"design/","page":"Design","title":"Design","text":"For experienced users, they can take an Application as a black box and reliably embed it in their own code logic. For some complex algorithms, they may even compose an arbitrary computation graph and schedule it on our cluster.","category":"page"},{"location":"design/#Application","page":"Design","title":"Application","text":"","category":"section"},{"location":"design/","page":"Design","title":"Design","text":"An application is usually a collection of Jugs or Saws which share the same runtime environment. Developers can specify the required resources to run the application. Our system may automatically create several instances based on the number of queueing requests.","category":"page"},{"location":"design/#Job","page":"Design","title":"Job","text":"","category":"section"},{"location":"design/","page":"Design","title":"Design","text":"To initiate the computation, Users need to submit a Job either through SDK or on the web portal.","category":"page"},{"location":"design/","page":"Design","title":"Design","text":"A job describes the target Jug/Saw and corresponding arguments.","category":"page"},{"location":"design/","page":"Design","title":"Design","text":"{\n    \"target\": {\n        \"app\": \"hello-world\",\n        \"method\": \"greet\"\n    },\n    \"arguments\": [\n        \"world\"\n    ]\n}","category":"page"},{"location":"design/","page":"Design","title":"Design","text":"The result of an job is a Future.","category":"page"},{"location":"design/#Jug","page":"Design","title":"Jug","text":"","category":"section"},{"location":"design/","page":"Design","title":"Design","text":"A Jug is a stateful computation unit. Each Jug is associated with a unique id.","category":"page"},{"location":"design/#Saw","page":"Design","title":"Saw","text":"","category":"section"},{"location":"design/","page":"Design","title":"Design","text":"A Saw is a stateless computation unit. Unlike Jug, there's no id associated with it.","category":"page"},{"location":"design/#Data-Model","page":"Design","title":"Data Model","text":"","category":"section"},{"location":"design/#Future","page":"Design","title":"Future","text":"","category":"section"},{"location":"design/","page":"Design","title":"Design","text":"A Future in Jugsaw is similar to the Future in Julia (or a kind of AbstractRemoteRef to be more specific). It is just an ID. Users can fetch the result from it with SDK.","category":"page"},{"location":"design/#Core-Components","page":"Design","title":"Core Components","text":"","category":"section"},{"location":"design/","page":"Design","title":"Design","text":"TODO: Add images to explain how they are assembled in our product.","category":"page"},{"location":"design/#Jugsaw-SDK","page":"Design","title":"Jugsaw SDK","text":"","category":"section"},{"location":"design/","page":"Design","title":"Design","text":"For now we'll focus on the Julia SDK. But the ideas should also apply to SDK in other languages in the future.","category":"page"},{"location":"design/","page":"Design","title":"Design","text":"Basically, the SDK contains two parts: the client side and the server side.","category":"page"},{"location":"design/#Jugsaw-Server","page":"Design","title":"Jugsaw Server","text":"","category":"section"},{"location":"design/","page":"Design","title":"Design","text":"Jug/Saw manager\n(De)Activate Jug/Saw\nDispatch requests\nState Monitoring","category":"page"},{"location":"design/","page":"Design","title":"Design","text":"note: Note\nThe manager is STATIC at the moment. This means that, once started, the manager can only handle requests to predefined Jugs or Saws.","category":"page"},{"location":"design/","page":"Design","title":"Design","text":"Example:","category":"page"},{"location":"design/","page":"Design","title":"Design","text":"# app.jl\n\n## Jug\ngreet(name::String=\"World\")::String = \"Hello, $name!\"\n\n## Saw\nBase.@kwdef struct Counter\n    name::String = greet()\n    n::Ref{Int} = Ref(0)\nend\n\n(c::Counter)(x::Int=1)::String = c.n[] += x","category":"page"},{"location":"design/","page":"Design","title":"Design","text":"# manager.jl\nusing Jugsaw\n\nregister(Jug, greet)\nregister(Saw, Counter)\n\nserve()","category":"page"},{"location":"design/","page":"Design","title":"Design","text":"# config.yaml\n- name: hello-world\n- version: v0.1.0\n- authors:\n  - Alice\n  - Bob","category":"page"},{"location":"design/#Jugsaw-Client","page":"Design","title":"Jugsaw Client","text":"","category":"section"},{"location":"design/","page":"Design","title":"Design","text":"Submit job\nFetch data from Future\n(De)Serializer","category":"page"},{"location":"design/","page":"Design","title":"Design","text":"using Jugsaw\n\nopen(Client(endpoint=\"https://api.jugsaw.co\"), app=\"hello-world\") do app\n    # Saw\n    msg = app.greet()\n    println(msg[])\n\n    # Jug\n    counter = app.Counter()\n    counter()\n    counter(2)\n    println(counter(3)[])\n\n    # JugSaw\n    x = app.Counter(name=app.greet())\n    x()\n    x(2)\n    println(string(x)[])\n\n    # Utils\n    signature(app.greet)\n    signature(app.count)\nend","category":"page"},{"location":"design/#Jugsaw-Runtime","page":"Design","title":"Jugsaw Runtime","text":"","category":"section"},{"location":"design/","page":"Design","title":"Design","text":"Scheduling\nAuto-scaling","category":"page"},{"location":"design/#Jugsaw-Proto","page":"Design","title":"Jugsaw Proto","text":"","category":"section"},{"location":"design/#Jugsaw-Frontend","page":"Design","title":"Jugsaw Frontend","text":"","category":"section"},{"location":"design/","page":"Design","title":"Design","text":"Communication strategy\nEmbedding in other tools\nJupyter Notebook\nPluto\nDocumenter.jl","category":"page"},{"location":"design/#Key-Features","page":"Design","title":"Key Features","text":"","category":"section"},{"location":"design/#Pluggable","page":"Design","title":"Pluggable","text":"","category":"section"},{"location":"design/#The-Ecosystem-Around-Jugsaw","page":"Design","title":"The Ecosystem Around Jugsaw","text":"","category":"section"},{"location":"design/#Comparison-with-Other-Products","page":"Design","title":"Comparison with Other Products","text":"","category":"section"},{"location":"design/","page":"Design","title":"Design","text":"HuggingFace Spaces\nReplicate\nRay\nPluto","category":"page"},{"location":"design/#FAQ","page":"Design","title":"FAQ","text":"","category":"section"},{"location":"design/#Why-do-You-Choose-to-Work-on-This-Field?","page":"Design","title":"Why do You Choose to Work on This Field?","text":"","category":"section"},{"location":"design/","page":"Design","title":"Design","text":"Our aspiration\nThe potential market size","category":"page"},{"location":"design/#Why-**You**?","page":"Design","title":"Why You?","text":"","category":"section"},{"location":"design/#Why-Julia?","page":"Design","title":"Why Julia?","text":"","category":"section"},{"location":"design/#References","page":"Design","title":"References","text":"","category":"section"},{"location":"design/","page":"Design","title":"Design","text":"Ray AIR Technical Whitepaper","category":"page"},{"location":"man/JugsawIR/","page":"Jugsaw IR","title":"Jugsaw IR","text":"DocTestSetup = quote\n    using JugsawIR\nend ","category":"page"},{"location":"man/JugsawIR/#Jugsaw-IR","page":"Jugsaw IR","title":"Jugsaw IR","text":"","category":"section"},{"location":"man/JugsawIR/","page":"Jugsaw IR","title":"Jugsaw IR","text":"JugsawIR is an intermediate representation (IR) for exposing and using cloud scientific applications. Its grammar is compatible with JSON at the time of writing, however, it might undergo a refactor to support richer features. The final form should be a real programming language for Web Virtual Machine.","category":"page"},{"location":"man/JugsawIR/","page":"Jugsaw IR","title":"Jugsaw IR","text":"Jugsaw IR can represent data, data types, and function calls. The basic rule is representing a Jugsaw object as a JSON object with extra constaints,","category":"page"},{"location":"man/JugsawIR/","page":"Jugsaw IR","title":"Jugsaw IR","text":"Integers, floating point numbers, Nothing, Missing, UndefInitializer, Symbol and String are directly representable.\nGeneric objects are represented by a JSON object with at most two fields: fields and type (optional).\nSome objects are specialized, including Array, Tuple, Dict, DataType and Enum.","category":"page"},{"location":"man/JugsawIR/#Examples-1:-Representing-Data","page":"Jugsaw IR","title":"Examples 1: Representing Data","text":"","category":"section"},{"location":"man/JugsawIR/","page":"Jugsaw IR","title":"Jugsaw IR","text":"julia> julia2ir(1.0+2im)[1] |> println\n{\"fields\":[1.0,2.0],\"type\":\"Base.Complex{Core.Float64}\"}","category":"page"},{"location":"man/JugsawIR/","page":"Jugsaw IR","title":"Jugsaw IR","text":"Or equivalently, as","category":"page"},{"location":"man/JugsawIR/","page":"Jugsaw IR","title":"Jugsaw IR","text":"{\"type\":\"Base.Complex{Core.Float64}\",\"fields\":[1.0,2.0]}","category":"page"},{"location":"man/JugsawIR/","page":"Jugsaw IR","title":"Jugsaw IR","text":"Or when calling a remote function, one can ommit the \"type\" specification, since the remote already has a copy of data types.","category":"page"},{"location":"man/JugsawIR/","page":"Jugsaw IR","title":"Jugsaw IR","text":"{\"fields\":[2,3]}","category":"page"},{"location":"man/JugsawIR/","page":"Jugsaw IR","title":"Jugsaw IR","text":"note: Note\nThe julia2ir function returns a two element tuple, a representation of object, and a TypeTable to delare types.","category":"page"},{"location":"man/JugsawIR/#Examples-2:-Representing-Data-Type","page":"Jugsaw IR","title":"Examples 2: Representing Data Type","text":"","category":"section"},{"location":"man/JugsawIR/","page":"Jugsaw IR","title":"Jugsaw IR","text":"A type is a special Jugsaw object with three fields name, fieldnames and fieldtypes. For example, to represent a complex number type, we can create the following IR","category":"page"},{"location":"man/JugsawIR/","page":"Jugsaw IR","title":"Jugsaw IR","text":"julia> julia2ir(ComplexF64)[1] |> println\n{\"fields\":[\"Base.Complex{Core.Float64}\",[\"re\",\"im\"],[\"Core.Float64\",\"Core.Float64\"]],\"type\":\"Core.DataType\"}","category":"page"},{"location":"man/JugsawIR/","page":"Jugsaw IR","title":"Jugsaw IR","text":"For convenience, JugsawIR returns a TypeTable instance to represent the types used in parsing.","category":"page"},{"location":"man/JugsawIR/#Examples-3:-Representing-Funcation-Call","page":"Jugsaw IR","title":"Examples 3: Representing Funcation Call","text":"","category":"section"},{"location":"man/JugsawIR/","page":"Jugsaw IR","title":"Jugsaw IR","text":"A function call is represented as a Jugsaw object with three fields fname, args and kwargs.","category":"page"},{"location":"man/JugsawIR/","page":"Jugsaw IR","title":"Jugsaw IR","text":"julia> fc = Call(sin, (2.0,), (;))\nsin(2.0; )\n\njulia> julia2ir(fc)[1] |> println\n{\"fields\":[{\"fields\":[],\"type\":\"Base.sin\"},{\"fields\":[2.0],\"type\":\"Core.Tuple{Core.Float64}\"},{\"fields\":[],\"type\":\"Core.NamedTuple{(), Core.Tuple{}}\"}],\"type\":\"JugsawIR.Call{Base.sin, Core.Tuple{Core.Float64}, Core.NamedTuple{(), Core.Tuple{}}}\"}","category":"page"},{"location":"man/JugsawIR/","page":"Jugsaw IR","title":"Jugsaw IR","text":"It is not different with regular Jugsaw object, except that it can executed when it is used to represent a remote call request.","category":"page"},{"location":"man/JugsawIR/#The-Grammar","page":"Jugsaw IR","title":"The Grammar","text":"","category":"section"},{"location":"man/JugsawIR/","page":"Jugsaw IR","title":"Jugsaw IR","text":"The grammar of JugsawIR in the EBNF format, which can be parsed by lark in Python, Lerche.jl in Julia and hopefully lark-js in Javascript.","category":"page"},{"location":"man/JugsawIR/","page":"Jugsaw IR","title":"Jugsaw IR","text":"object: genericobj1\n        | genericobj2\n        | genericobj3\n        | list\n        | string\n        | number\n        | true\n        | false\n        | null\n\ngenericobj1 : \"{\" \"\\\"fields\\\"\" \":\" list \"}\"\ngenericobj2 : \"{\" \"\\\"type\\\"\" \":\" ESCAPED_STRING \",\" \"\\\"fields\\\"\" \":\" list \"}\"\ngenericobj3 : \"{\" \"\\\"fields\\\"\" \":\" list \",\" \"\\\"type\\\"\" \":\" ESCAPED_STRING \"}\"\n\nlist : \"[\" [object (\",\" object)*] \"]\"\nstring : ESCAPED_STRING\nnumber : SIGNED_NUMBER\ntrue : \"true\"\nfalse : \"false\"\nnull : \"null\"\n\n%import common.ESCAPED_STRING\n%import common.SIGNED_NUMBER\n%import common.WS\n%ignore WS","category":"page"},{"location":"man/JugsawIR/#APIs","page":"Jugsaw IR","title":"APIs","text":"","category":"section"},{"location":"man/JugsawIR/","page":"Jugsaw IR","title":"Jugsaw IR","text":"Modules = [JugsawIR]\nOrder = [:function, :macro, :type, :module]","category":"page"},{"location":"","page":"Home","title":"Home","text":"CurrentModule = Jugsaw","category":"page"},{"location":"#Jugsaw","page":"Home","title":"Jugsaw","text":"","category":"section"},{"location":"","page":"Home","title":"Home","text":"Documentation for Jugsaw - a toolkit for deploying your Julia functions to the cloud.","category":"page"},{"location":"#Manual","page":"Home","title":"Manual","text":"","category":"section"},{"location":"","page":"Home","title":"Home","text":"Pages = [\n    \"get-started.md\",\n]\nDepth = 1","category":"page"}]
}
