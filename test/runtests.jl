using Poirot, Test

@testset "Poirot" begin

@testset "Abstract" begin
  include("abstract.jl")
end

@testset "Inference" begin
  include("inference.jl")
end

end
