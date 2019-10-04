using Poirot, Test, Random

Random.seed!(0)

d = infer() do
  i = rand(Uniform(1,10))
  i^2 > 50
end

@test 0.3 < mean(d) < 0.35
