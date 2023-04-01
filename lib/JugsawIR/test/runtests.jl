using Test
using JugsawIR: @parsetype, json4, parse4
using JugsawIR
using JSON

function convert_json(obj)
    io = IOBuffer()
    jio = JugsawIR.JSON4Context(io)
    JSON.begin_array(jio)
    JSON.show_json(jio, JSON.StandardSerialization(), obj)
    JSON.end_array(jio)
    return String(take!(io)), jio.extra_types
end

@testset "DataType" begin
    c = "[\"Complex{Float64}\"]"
    @test json4(ComplexF64) == c
    @test parse4(c) == Any[ComplexF64]
    ref3 = "[{\"__type__\":\"DataType\",\"name\":\"RefValue{Int64}\",\"fieldtypes\":[\"Int64\"]}, {\"__type__\":\"RefValue{Int64}\",\"x\":3}]"
    @test json4(Ref(3)) == ref3
end

@testset "parsetype" begin
    c(x) = JSON.parse(JSON.json(x))
    argtype = Tuple{Int32, Float32, Tuple{Int, String}, String, Bool, Dict{String, ComplexF32}, Dict{String, ComplexF32}, ComplexF32, Vector{ComplexF64}}
    args = [3, 3.0, [4, "4"], "x", false, Dict("x" => c(1+2im), "y"=>c(3+4.0im)), Dict(:x => c(1+2im), :y=>c(3+4.0im)), c(2-im), [3.0, 1.0]]
    res = @parsetype(argtype, args)
    @test res isa argtype
    @test @parsetype(NamedTuple{(:x, :y, :z), Tuple{String, Int, Int}}, Dict("x"=>"z", "y"=>3.0, "z"=>4, "k"=>2)) == (x="z", y=3, z=4)
end

@testset "type string" begin
    struct S{T, C}
    end
    for (A, B) in [(ComplexF64, "Complex{Float64}"), (Float64, "Float64"), (Array{Float64, 3}, "Array{Float64, 3}"), (S{Float64, ComplexF64}, "S{Float64, Complex{Float64}}")]
        @test JugsawIR.type2str(A) == B
        @test JugsawIR.str2type(@__MODULE__, B) == A
    end
end

@testset "json4" begin
    # typed parse
    for obj in [
        2.0, 3, 2f0, 3+2im, "x", nothing, true, :x, UInt8(3),
        (1, 2), [1, 2, 3], [1+2im, 2+3im], (; x=4, y=5),
        Dict("complex"=>1+2im,
            "Tensor"=> randn(3,3),
            "Graph" => JugsawIR.Graph(6, [2 4 1; 3 1 6]),
            )
        ]
        @info typeof(obj)
        str = json4(obj)
        res = parse4(str; type=typeof(obj))
        @test obj == res
    end
end
