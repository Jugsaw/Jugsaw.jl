## Deploy a Jugsaw app

To deploy a Jugsaw app, you must have a Jugsaw account. You can a free account from [https://www.jugsaw.co](https://www.jugsaw.co). To setup a new Jugsaw app, you should go through the following steps

1: Create a Jugsaw App in any folder of a Github repository.
```julia
julia> using Jugsaw

julia> Jugsaw.Template.init(:Test)
[ Info: Generated Jugsaw app `Test` at folder: /home/leo/jcode/Jugsaw/Test
┌ Info: Success, please type `julia --project server.jl` to debug your application locally.
└ To upload your application to Jugsaw website, please check https://jugsaw.github.io/Jugsaw/dev/developer

julia> readdir("Test")
5-element Vector{String}:
 "Dockerfile"     # The script for specifying how docker images are built
 "Project.toml"   # Julia package environment specification
 "README"         # A description of the Jugsaw app
 "app.jl"         # Jugsaw app, which contains functions and tests
 "server.jl"      # A script for serving the app
```
2. Following the printed help message, you can live serve the application locally and edit the generated template project.
The edit will be reflected immediately to the service, which is supported by [Revise](https://github.com/timholy/Revise.jl).
Once you app is ready, please check [deploy guide](https://jugsaw.github.io/Jugsaw/dev/developer) for a detailed guide.

<details>
  <summary>Alternative: using Github Actions</summary>
You should add your Jugsaw deploy key to your repository secrets.
A Jugsaw deploy key can be obtained from the Jugsaw website -> Profile -> Deploy Key.

To set up repository secrets for GitHub action, follow the steps below:

1. Go to the GitHub repository where you want to set up the secrets.
2. Click on the "Settings" tab.
3. Click on the "Secrets" option.
4. Click on the "New repository secret" button.
5. Enter the name of the secret in the "Name" field as "JUGSAW_DEPLOY_KEY".
6. Enter the value of the secret in the "Value" field.
7. Click on the "Add secret" button.

In your GitHub action workflow file, reference the secrets using the syntax ${{ secrets.SECRET_NAME }}.

Note: It's important to keep your secrets secure and not include them in your code or make them publicly available.
</details>

## Run a Jugsaw App
* An *instance* is a living or hibernated container running a Julia session.
The wake up time of a hibernated container is under 0.5s (goal).
* An *endpoint* is the URI of a computational resource vendor, which can be a localhost, a shared EC2 or a cluster.

### Using shared nodes
The following is an example of launching a Jugsaw app on the shared endpoint with the Julia language (we have multiple clients).

```julia
julia> using JugsawClient

julia> msg = open(JugsawClient.SharedNode(
                endpoint="https://api.jugsaw.co"),
                app="hello-world",
                uuid="79dccd12-cad8-11ed-387a-f9e5b0f14a94",
                keep=true) do app
        app.greet("World")
    end;

julia> println(msg["result"]) # the result
Hello World!

julia> println(msg["uuid"])   # the instance id
"79dccd12-cad8-11ed-387a-f9e5b0f14a94"

julia> println(msg["time"])   # time in seconds
0.001

julia> println(msg["exit code"])   # exit code
0
```

**Rules**
* If uuid is not specified, then the function will be executed on the shared instance (if any).
* If uuid is specified, then the specific instance will be used (may throw `InstanceNotExistError`).
* Unless `keep` is true, an instance will be killed after being inactive for 20min.

A free tier user can keep at most 10 instances at the same time.
Please go to the [control panel]() to free some instances if you see a `InstanceQuotaError` or subscribe our [Jugsaw premium]().

### Using cluster nodes

The following is an example of launching a Jugsaw app on a cluster with Julia language (we have multiple clients).
```julia
julia> using JugsawClient

julia> msg = open(JugsawClient.ClusterNode(
                endpoint="https://api.hkust-cluster.edu.cn"),
                app="hello-world",
                ncpu = 5,
                ngpu = 1,
                usempi = false,
                usecuda = true,
                timelimit = 3600,   # in seconds
                ) do app
        app.greet("World")
    end;
[ Info: You can manage your job with this URI: https://api.hkust-cluster.edu.cn/monitor/79dccd12-cad8-11ed-387a-f9e5b0f14a94/

julia> println(msg["exit code"])   # exit code
0
```

**Rules**
* Cluster Jugsaw call is stateless.
* There might be an overhead in using clusters. Cluster pull the reqested app from `jugsaw.co` to local, create a `singularity` instance, and launch the job.
* The result is not returned directly, instead, one should use the returned URI to access the result and manage the jobs.