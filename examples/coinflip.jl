using Poirot, UnicodePlots

# Model
model(weight) = rand() < weight
model(weight, N) = [model(weight) for _ = 1:N]

# Fake data
N = 100
data = model(0.7, N)

# Inference setup
J = Rejection((a, b) -> mean(a) ≈ mean(b))

# Running inference
infer = J(θ -> model(θ, N), Uniform(0, 1))
posterior, = infer(data)

histogram(posterior.data)
