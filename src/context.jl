# `partial(F, Ts...)`: called by the top-level tracer and allowed to directly
# evaluate side effects.

# `mutate(MutCtx, F, Ts...)`: called by the abstract interpreter, and allowed
# to abstractly interpret side effects.

# `abstract(F, Ts...)`: Side-effect-agnostic fallback, called by both stages of
# compilation.

abstract(Ts...) = nothing
partial(Ts...) = abstract(Ts...)
mutate(context, Ts...) = abstract(Ts...)
