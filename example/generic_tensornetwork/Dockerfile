ARG JULIA_VERSION=1
FROM julia:$JULIA_VERSION

ARG JULIA_PKG_SERVER
ENV JULIA_PKG_SERVER=${JULIA_PKG_SERVER:-https://pkg.julialang.org}

# FIXME: no need to develop Jugsaw once it is registered
COPY . /jugsaw
WORKDIR /jugsaw/example/generic_tensornetwork/app
RUN julia --project=. -e "using Pkg; Pkg.instantiate()"

EXPOSE 8081
ENTRYPOINT ["julia", "--project=.", "app.jl"]