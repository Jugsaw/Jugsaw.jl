using Test

@testset "jobhandler" begin
    include("jobhandler.jl")
end

@testset "liveserve.jl" begin
    include("simpleserver.jl")
end
