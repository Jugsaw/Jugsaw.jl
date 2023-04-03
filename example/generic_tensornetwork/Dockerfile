ARG JULIA_VERSION=1
FROM julia:$JULIA_VERSION

# FIXME: no need to develop Jugsaw once it is registered
COPY . /workspace
WORKDIR /workspace/example/hello_world
RUN julia --project=. -e "using Pkg; Pkg.instantiate()"

EXPOSE 8081
ENTRYPOINT ["julia", "--project=.", "app.jl"]