ARG JULIA_VERSION=1
FROM julia:$JULIA_VERSION

# FIXME: no need to develop Jugsaw once it is registered
COPY . /workspace
WORKDIR /workspace/example/hello_world/app
RUN julia --project=. -e "using Pkg; Pkg.instantiate()"

EXPOSE 8088
ENTRYPOINT ["julia", "--project=.", "app.jl"]

LABEL jugsaw.demos = "{\"fields\":[\"helloworld\",{\"fields\":[[2],[\"greet\",\"identity\"]],\"type\":\"JugsawIR.JArray{Core.String}\"},{\"fields\":[{\"fields\":[[2],[{\"fields\":[\"greet\",{\"fields\":[[1],[{\"fields\":[{\"fields\":[\"greet\",{\"fields\":[\"Jinguo\"],\"type\":\"Core.Tuple{Core.String}\"},{\"fields\":[],\"type\":\"Core.NamedTuple{(), Core.Tuple{}}\"}],\"type\":\"JugsawIR.Call\"},\"Hello, Jinguo\",{\"fields\":[{\"fields\":[[6],[{\"fields\":[\"args_type\",\"Core.Tuple{Core.String}\"],\"type\":\"Core.Pair{Core.String, Core.String}\"},{\"fields\":[\"api_julialang\",\"using Jugsaw.Client\\napp = reques" ⋯ 5612 bytes ⋯ ".log)\\n</script>\"],\"type\":\"Core.Pair{Core.String, Core.String}\"}]],\"type\":\"JugsawIR.JArray{Core.Pair{Core.String, Core.String}}\"}],\"type\":\"JugsawIR.JDict{Core.String, Core.String}\"}],\"type\":\"JugsawIR.JugsawDemo\"}]],\"type\":\"JugsawIR.JArray{JugsawIR.JugsawDemo}\"}],\"type\":\"Core.Pair{Core.String, Core.Array{JugsawIR.JugsawDemo, 1}}\"}]],\"type\":\"JugsawIR.JArray{Core.Pair{Core.String, Core.Array{JugsawIR.JugsawDemo, 1}}}\"}],\"type\":\"JugsawIR.JDict{Core.String, Core.Array{JugsawIR.JugsawDemo, 1}}\"}],\"type\":\"Jugsaw.AppSpecification\"}"
LABEL jugsaw.types = "{\"fields\":[{\"fields\":[[21],[\"Jugsaw.AppSpecification\",\"JugsawIR.JArray{Core.String}\",\"JugsawIR.JDict{Core.String, Core.Array{JugsawIR.JugsawDemo, 1}}\",\"JugsawIR.JArray{Core.Pair{Core.String, Core.Array{JugsawIR.JugsawDemo, 1}}}\",\"Core.Pair{Core.String, Core.Array{JugsawIR.JugsawDemo, 1}}\",\"JugsawIR.JArray{JugsawIR.JugsawDemo}\",\"JugsawIR.JugsawDemo\",\"JugsawIR.Call\",\"Core.Tuple{Core.String}\",\"Core.NamedTuple{(), Core.Tuple{}}\",\"JugsawIR.JDict{Core.String, Core.String}\",\"JugsawIR.JArray{Core.Pair{Core.String, Core.String}}\",\"C" ⋯ 8722 bytes ⋯ "ore.String, JugsawIR.JDataType}\"},{\"fields\":[\"Core.Pair{Core.Int64, Core.Int64}\",{\"fields\":[\"Core.Pair{Core.Int64, Core.Int64}\",{\"fields\":[[2],[\"first\",\"second\"]],\"type\":\"JugsawIR.JArray{Core.String}\"},{\"fields\":[[2],[\"Core.Int64\",\"Core.Int64\"]],\"type\":\"JugsawIR.JArray{Core.String}\"}],\"type\":\"JugsawIR.JDataType\"}],\"type\":\"Core.Pair{Core.String, JugsawIR.JDataType}\"}]],\"type\":\"JugsawIR.JArray{Core.Pair{Core.String, JugsawIR.JDataType}}\"}],\"type\":\"JugsawIR.JDict{Core.String, JugsawIR.JDataType}\"}],\"type\":\"JugsawIR.TypeTable\"}"
LABEL jugsaw.code.julia = "Typical Julia Code"
LABEL jugsaw.code.python = "Python Code Example"
