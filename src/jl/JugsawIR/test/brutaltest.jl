using Test, JugsawIR

@testset "hard objects" begin
    brutal_obj_demos = [
        (2.0, 3.0)
    ]
    for (obj, demo) in brutal_obj_demos
        @test test_twoway(obj, demo)
    end
end