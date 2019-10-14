using Poirot, Test, Random
using Poirot: Singleton

Random.seed!(0)

@test infer(() -> 1) == Singleton(1)
@test infer(() -> "foo") == Singleton("foo")

d = infer() do
  i = rand(Uniform(1,10))
  i^2 > 50
end

@test 0.3 < mean(d) < 0.35
