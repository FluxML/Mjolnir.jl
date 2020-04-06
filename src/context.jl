# `partial(F, Ts...)`: called by the top-level tracer and allowed to directly
# evaluate side effects.

# `mutate(MutCtx, F, Ts...)`: called by the abstract interpreter, and allowed
# to abstractly interpret side effects.

# `abstract(F, Ts...)`: Side-effect-agnostic fallback, called by both stages of
# compilation.

# P is the set of primitives in use.

instead(P, args, Ts...) = nothing
abstract(P, Ts...) = nothing
partial(P, Ts...) = abstract(P, Ts...)
mutate(P, context, Ts...) = abstract(P, Ts...)

function something(f, xs)
  for x in xs
    y = f(x)
    y === nothing || return y
  end
  return
end

struct Multi{Ps<:Tuple}
  ps::Ps
  Multi(ps...) = new{typeof(ps)}(ps)
end

instead(m::Multi, args, Ts...) = something(p -> instead(p, args, Ts...), m.ps)
abstract(m::Multi, Ts...) = something(p -> abstract(p, Ts...), m.ps)
partial(m::Multi, Ts...)  = something(p ->  partial(p, Ts...), m.ps)
mutate(m::Multi, cx, Ts...)  = something(p ->  mutate(p, cx, Ts...), m.ps)

Defaults() = Multi(Basic(), Numeric())
