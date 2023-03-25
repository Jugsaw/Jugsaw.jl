# Get started
![](framework.png)

1. Deploy a Jugsaw app and run the Jugsaw app.
## Deploy a Jugsaw App

First, you should have a Jugsaw account. You may get one from [https://www.jugsaw.co](https://www.jugsaw.co).
To setup a new Jugsaw App, you should go through the following process

1: Create a Jugsaw App in any folder of a Github repository.
```julia
julia> using Jugsaw

julia> Jugsaw.template("hello-world")
[ Info: Generated Jugsaw app "hello-world" at folder: "jugsaw"

julia> readdir("jugsaw")
5-element Vector{String}:
 ".gitignore"     #
 "Project.toml"   # environment specific cation
 "app.jl"         # functions and tests
 "config.yaml"    # jugsaw app setting
 "manager.jl"     # deployment manager
```
2. Edit the generated template project.

3. Register your Jugsaw App.
    1. Go to [https://www.jugsaw.co/apps](https://www.jugsaw.co/apps).
    2. Click "Create a new Jugsaw App".
    3. Enter the Github repo and the subfolder containing your Jugsaw App.

Once your Jugsaw App is ready, you will recieve an email notification.

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
### Terms
* *instance* is a living or hibernated container running a Julia session.
The wake up time of a hibernated container is under 0.5s (goal).
* *endpoint* is the URI of a computational resource vendor, which can be a localhost, a shared EC2 or a cluster.

### Using shared nodes
**Rules**
* If uuid is not specified, then the function will be executed on the shared instance (if any).
* If uuid is specified, then the specific instance will be used (may throw `InstanceNotExistError`).
* Unless `keep` is true, an instance will be killed after being inactive for 20min.

A free tier user can keep at most 10 instances at the same time.
Please go to the [control panel]() to free some instances if you see a `InstanceQuotaError` or subscribe our [Jugsaw premium]().

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

### Using cluster nodes

**Rules**
* Cluster Jugsaw call is stateless.
* There might be an overhead in using clusters. Cluster pull the reqested app from `jugsaw.co` to local, create a `singularity` instance, and launch the job.
* The result is not returned directly, instead, one should use the returned URI to access the result and manage the jobs.

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