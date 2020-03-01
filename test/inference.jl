using Poirot, Test, Random
using Poirot: Singleton

Random.seed!(0)

@test infer(() -> 1) == Singleton(1)
@test infer(() -> "foo") == Singleton("foo")

@test infer(() -> rand()) == Uniform(0, 1)
@test infer(() -> randn()) == Normal(0, 1)
@test infer(() -> rand(Bool)) == Bernoulli(1//2)

coin() = rand(Bool)

@test infer(() -> coin() & coin()) == Bernoulli(0.25)
@test infer(() -> coin() | coin()) == Bernoulli(0.75)

@test infer() do
  a = coin()
  b = coin()
  observe(a | b)
  a & b
end == Bernoulli(1/3)

infer() do
  a = coin()
  b = coin()
  observe(a | b)
  observe(!b)
  a
end == Singleton(true)

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

d = infer() do
  identical = rand(Bernoulli(1/3))
  boy1 = rand(Bernoulli(1/2))
  # TODO first version gives a different answer
  # boy2 = identical ? boy1 : rand(Bernoulli(1/2))
  boy2 = rand(Bernoulli(identical ? boy1*1.0 : 1/2))
  observe(boy1 & boy2)
  identical
end

@test mean(d) == 0.5
