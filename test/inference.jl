using Poirot, Test, Random
using Poirot: Singleton

Random.seed!(0)

@test infer(() -> 1) == Singleton(1)
@test infer(() -> "foo") == Singleton("foo")

@test infer(() -> rand(Normal(0, 1))) == Normal(0, 1)
@test infer(() -> rand(Bernoulli(0.5))) == Bernoulli(0.5)

coin() = rand(Bernoulli(0.5))

@test infer(() -> coin() & coin()) == Bernoulli(0.25)
@test infer(() -> coin() | coin()) == Bernoulli(0.75)

@test infer() do
  a = coin()
  b = coin()
  observe(a | b)
  a & b
end == Bernoulli(1/3)

@test infer() do
  x = rand(Normal(0, 1))
  observe(x > 0)
  x
end isa Poirot.Empirical

d = infer() do
  x = rand(Uniform(0,10))
  x^2 > 50
end

@test d isa Bernoulli
@test mean(d) ≈ (10-sqrt(50))/10

d = infer() do
  x = rand(Uniform(0,10))
  observe(x > 5)
  x^2 > 50
end

@test d isa Bernoulli
@test mean(d) ≈ (10-sqrt(50))/5
