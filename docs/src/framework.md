# Framework
```@raw html
<script type="module">
  import mermaid from 'https://cdn.jsdelivr.net/npm/mermaid@9/dist/mermaid.esm.min.mjs';
  mermaid.initialize({ startOnLoad: true, securityLevel: 'loose' });
</script>
```

## Deployment stage
Jugsaw applications are deployed through Github action. The CI/CD script is already included in the generated template, which includes the following steps of deployment
1. Build a docker image,
2. Push the docker image to the developer's docker registry. This docker registry user account is connected with the developer's Jugsaw website user account,
3. Pull up the service on a shared node. In the future, elastic computational resources will be available.

```@raw html
<div class="mermaid">
    graph LR;
    App(Jugsaw app)-->Github((Github Action));
    Github-->Docker("Jugsaw docker registry\n(harbor.jugsaw.co)");
    Docker-->Endpoint("Jugsaw's endpoint\n(jugsaw.co)");
    classDef bluenode fill:white,stroke:#3d85c6,stroke-width:2px,text-align:center,line-height:20px;
    class App,Docker,Endpoint,Github bluenode;
    click Docker href "http://harbor.jugsaw.co" "Go to Jugsaw docker registry to browse registered images"
    click Endpoint href "http://www.jugsaw.co" "Go to Jugsaw website to browse apps"
    style Endpoint color:#00f
    style Docker color:#00f
</div>
```

## Serving stage
Clients can access deployed Jugsaw apps by posting a request to an endpoint. The endpoint can be either [jugsaw.co](jugsaw.co), or a local host that you are testing on.
The function payload in the function call requests are represented as Jugsaw' intermediate representation, or *Jugsaw IR*.
The results in the response (to fetch operation) from server are also represented in *Jugsaw IR*.
```@raw html
<div class="mermaid">
    graph LR;
    Julia(Julia)-->IR((Jugsaw IR));
    Python(Python)-->IR;
    Javascript(Javascript)-->IR;
    IR-->Server(Endpoint);
    classDef bluenode fill:white,stroke:#3d85c6,stroke-width:2px,text-align:center,line-height:20px;
    class Julia,IR,Python,Javascript,Server bluenode;
</div>
```

### Endpoint

Jugsaw starts service on `0.0.0.0:8088` by default.
The route table of a Jugsaw server could be found in [`Jugsaw.Server.serve`](@ref).

### Jugsaw IR
The design of Jugsaw IR is detailed in the section [JugsawIR](@ref).