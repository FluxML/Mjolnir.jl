# Dumbest possible nested integration method

struct Quad end

select(::Type{Bool}, r, p) = r ? [exp(p), 0] : [0, exp(p)]

normalise(p) = p ./ sum(p)

distribution(::Type{Bool}, ps) = Bernoulli(normalise(ps)[1])

quad(f, ::Type{<:Real}) = quadgk(f, -Inf, Inf)[1]

function infer(f, ::Quad, tr = trace(typeof(f)))
  r = returntype(tr)
  r == Bool || return
  lprob, vars = logprob(tr)
  Ts = [T for (v, T) in vars]
  lprob = func(lprob)
  f = (vars...) -> select(r, Base.invokelatest(lprob, f, vars)...)
  distribution(r, quad(f, Ts...))
end
