# `partial(F, Ts...)`: called by the top-level tracer and allowed to directly
# evaluate side effects.

# `mutate(MutCtx, F, Ts...)`: called by the abstract interpreter, and allowed
# to abstractly interpret side effects.

# `abstract(F, Ts...)`: Side-effect-agnostic fallback, called by both stages of
# compilation.

# P is the set of primitives in use.

abstract(P, Ts...) = nothing
partial(P, Ts...) = abstract(P, Ts...)
mutate(P, context, Ts...) = abstract(P, Ts...)

struct Defaults end
