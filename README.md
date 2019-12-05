<p align="center">
<img width="400px" src="https://raw.githubusercontent.com/FluxML/fluxml.github.io/master/poirot.png"/>
</p>

[![Build Status](https://travis-ci.org/MikeInnes/Poirot.jl.svg?branch=master)](https://travis-ci.org/MikeInnes/Poirot.jl)

```julia
] add https://github.com/MikeInnes/XLATools.jl
] add https://github.com/MikeInnes/Poirot.jl
```

Poirot contains a series of experiments in probabilistic programming, both at the interface level and in terms of the abstract tracing used to implement it. Note that as an early prototype, anything not explicitly stated to work probably doesn't.

As a modelling language, Poirot has two intertwined main goals:

1. Poirot's modelling language should abstract over a range of inference methods, from analytical methods, to factor graph representations, to monte carlo and ABC. Compiler analysis allows us to (automatically) choose an appropriate representation compatible with the best possible inference algorithm. There is no "static"/"dynamic" modelling distinction.
2. If you have no idea what any of (1) means, you should still be able to use Poirot productively, learning about more advanced concepts as you go.

## Probablistic Modelling

It easy to write randomised programs in Julia. They can be as short as one line!

```julia
julia> randn()
1.3664118530820202
```

Poirot adds a new construct to Julia, the `infer` block. Infer turns a stochastic program into a deterministic one: instead of getting back a single random value, you get a distribution of possible values.

```julia
julia> using Poirot

julia> infer() do
         randn()
       end
Normal{Float64}(μ=0.0, σ=1.0)

julia> infer() do
         rand(Bool)
       end
Bernoulli{Rational{Int64}}(p=1//2)
```

Of course, we know what those functions return already. What about something more complex? For example: what's the chance of two coins both being heads?

```julia
julia> coin() = rand(Bool)
coin (generic function with 1 method)

julia> coin() & coin()
false

julia> infer() do
         coin() & coin()
       end
Bernoulli{Float64}(p=0.25)
```

The second construct Poirot adds is the `observe` function. This essentially behaves like an `assert`; you provide a condition, and if it's false, it errors out.

```julia
julia> begin
         a = coin()
         b = coin()
         observe(a | b)
         a & b
       end
true

julia> begin
         a = coin()
         b = coin()
         observe(a | b)
         a & b
       end
ERROR: Poirot.ConditionError()
```

The key thing about `observe` is that it _changes what kinds of outputs the function produces_, since many cases now error instead of returning anything. In this case, we're effectively asking for the probability that two coins are heads _given_ that at least one of them is (implied by `observe(a | b)`).

```julia
julia> infer() do
         a = coin()
         b = coin()
         observe(a | b)
         a & b
       end
Bernoulli{Float64}(p=0.3333333333333333)
```

We can use this kind of probabilistic reasoning to solve all kinds of statistical problems, and it even subsumes regular logical inference. For example: If `a` or `b` is true, but `b` isn't true, `a` must be true (with 100% probability).

```julia
julia> infer() do
         a = coin()
         b = coin()
         observe(a | b)
         observe(!b)
         a
       end
Singleton(true)
```

We can use this as a kind of statistical pocket calculator. For example: you take a test which is 99% accurate<sup>\*</sup>, for a disease that affects one in one hundred thousand people. How likely is it that you have the disease?

(\*both sensitivity and specificity, for simplicity)

```julia
julia> infer() do
         disease = rand(Bernoulli(1/100_000))
         test = rand(Bernoulli(0.99)) ? disease : !disease
         observe(test)
         disease
       end
Bernoulli{Float64}(p=0.0009890307498651321)
```

Surprisingly, very unlikely!

This also covers more advanced models, such as a linear regression (hypothetical example, since HMC is not hooked up):

```julia
x, y = # ...
infer() do
  slope = rand(Normal(0, 1))
  intercept = rand(Normal(0, 1))
  ŷ = x .* slope .+ intercept .+ randn.()
  observe(y == ŷ)
  slope, intercept
end
```

Larger and more complex models can easily be factored into functions and use data structures, and to separate modelling from inference. Inference can also be easily customised with calls like `infer(HMC(...)) do ...` or `infer(model, HMC(...))`.
