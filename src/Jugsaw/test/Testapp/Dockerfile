ARG JULIA_VERSION=1.0.0
FROM julia:$JULIA_VERSION

# FIXME: no need to develop Jugsaw once it is registered
COPY . /Testapp
WORKDIR /Testapp
# The environment varialbe `JUGSAW_SERVER=DOCKER` turns the local mode off
RUN JUGSAW_SERVER=DOCKER julia --project=. -e "using Pkg; Pkg.instantiate()"

EXPOSE 8081
ENTRYPOINT ["julia", "--project=.", "app.jl"]
