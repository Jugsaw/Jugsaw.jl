using Test, JugsawIR
using JugsawIR: test_twoway
using Dates

@testset "hard objects" begin
    brutal_obj_demos = [
        (Dict(2=>3), Dict())
    ]
    for (obj, demo) in brutal_obj_demos
        @test_throws Union{TypeError, TypeTooAbstract, MethodError} test_twoway(obj, demo)
    end
end

############### Credit: Many of the following tests are copied from JSON3.
@testset "simple" begin
    struct data
        t :: Tuple{Symbol, String}
    end
    @test test_twoway(data((:test, "ds")))
end

@testset "undef" begin
    @testset "undef" begin
        mutable struct UndefGuy
            id::Int
            name::String
            UndefGuy() = new()
        end
    end
    @test_broken test_twoway(UndefGuy())
end

@testset "date struct" begin
    mutable struct DateStruct
        date::Date
        datetime::DateTime
        time::Time
    end
    DateStruct() = DateStruct(Date(0), DateTime(0), Time(0))
    @test test_twoway(DateStruct())
end

@testset "named tuple" begin
    struct Wrapper
        x::NamedTuple{(:a, :b), Tuple{Int, String}}
    end
    @test test_twoway(Wrapper((; a=3, b="s")))
end

@testset "named tuple" begin
    Base.@kwdef mutable struct System
        duration::Real = 0 # mandatory
        cwd::Union{Nothing, String} = nothing
        environment::Union{Nothing, Dict} = nothing
        batch::Union{Nothing, Dict} = nothing
        shell::Union{Nothing, Dict} = nothing
    end
    @test test_twoway(System(; duration=1, cwd="xxx"))
end

@testset "tree" begin
    struct Node
        value::Symbol
        children::Vector{Node}
    end
    demo = Node(:z, [Node(:x, Node[]), Node(:y, [Node(:a, Node[])])])
    obj = Node(:z, [Node(:x, Node[]), Node(:y, Node[]), Node(:a, Node[])])
    JugsawIR.demoof(::Type{Node}) = Node(:x, Node[])
    @test test_twoway(obj, demo)
end