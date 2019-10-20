# Dumbest possible nested integration method

struct Quad end

select(::Type{Bool}, r, p) = r ? [exp(p), 0] : [0, exp(p)]

function normalise(p)
  s = sum(p)
  s == 0 && error("Conditions are unsatisfiable")
  p ./ s
end

distribution(::Type{Bool}, ps) = collapse(Bernoulli(normalise(ps)[1]))

quad(f) = f()

quad(f, ::Type{<:Real}, Ts...) =
  quadgk(x -> quad((xs...) -> f(x, xs...), Ts...),
         -Inf, Inf)[1]

quad(f, ::Type{Bool}, Ts...) =
  quad((xs...) -> f(true, xs...), Ts...) +
  quad((xs...) -> f(false, xs...), Ts...)

function infer(f, ::Quad, tr = trace(typeof(f)))
  r = returntype(tr)
  r == Bool || return
  lprob, vars = logprob(tr)
  Ts = [T for (v, T) in vars]
  lprob = func(lprob)
  f = (vars...) -> select(r, Base.invokelatest(lprob, f, vars)...)
  distribution(r, quad(f, Ts...))
end
