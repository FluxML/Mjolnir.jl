using Poirot, Test, Random
using Poirot: Singleton

Random.seed!(0)

@test infer(() -> 1) == Singleton(1)
@test infer(() -> "foo") == Singleton("foo")

@test infer(() -> rand()) == Uniform(0, 1)
@test infer(() -> randn()) == Normal(0, 1)
@test infer(() -> rand(Bool)) == Bernoulli(0.5)

coin() = rand(Bool)

@test infer(() -> coin() & coin()) == Bernoulli(0.25)
@test infer(() -> coin() | coin()) == Bernoulli(0.75)

@test infer() do
  a = coin()
  b = coin()
  observe(a | b)
  a & b
end == Bernoulli(1/3)

@test infer() do
  x = randn()
  observe(x > 0)
  x
end isa Poirot.Empirical

d = infer() do
  x = 10*rand()
  x^2 > 50
end

@test d isa Bernoulli
@test mean(d) ≈ (10-sqrt(50))/10

d = infer() do
  x = 10*rand()
  observe(x > 5)
  x^2 > 50
end

@test d isa Bernoulli
@test mean(d) ≈ (10-sqrt(50))/5
