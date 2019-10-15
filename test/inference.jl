using Poirot, Test, Random
using Poirot: Singleton

Random.seed!(0)

@test infer(() -> 1) == Singleton(1)
@test infer(() -> "foo") == Singleton("foo")

@test infer(() -> rand(Normal(0, 1))) == Normal(0, 1)
@test infer(() -> rand(Bernoulli(0.5))) == Bernoulli(0.5)

@test infer() do
  x = rand(Normal(0, 1))
  observe(x > 0)
  x
end isa Poirot.Empirical

d = infer() do
  i = rand(Uniform(1,10))
  i^2 > 50
end

@test 0.3 < mean(d) < 0.35
