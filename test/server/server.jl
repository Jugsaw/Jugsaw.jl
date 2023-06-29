using Test

@testset "jobhandler" begin
    include("jobhandler.jl")
end

@testset "simpleserver.jl" begin
    include("simpleserver.jl")
end
