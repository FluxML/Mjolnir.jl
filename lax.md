# LAX

Poirot's secret sauce is a mechanism for de-abstracting Julia source code, from
something that uses high-level function calls and data structures to simple
mathematical and numerical operations. This is useful any time that we can't
easily support a full programming language; probabilistic programming is one
example, but another is compiling to accelerators like XLA, which only accept a
limited set of operations.

Some limited XLA support is exposed in Poirot via the `xla` function.

```julia
julia> using Poirot.LAX

julia> x = rand(3); y = rand(3);

julia> xla() do
         x + y
       end
3-element XLATools.XArray{Float64,1}:
 0.1711469514388062
 1.356556481649867
 0.8388503162815957
```

This returns `XArray`s that are owned by the XLA runtime, but you can convert
them back to arrays easily.

We can define functions that always use XLA.

```julia
julia> relu(x) = xla(() -> x > 0 ? x : 0)
relu (generic function with 1 method)

julia> relu(5)
5

julia> relu(-5)
0
```

[This (roughly) follows Julia's compilation model, so we're not re-compiling
every time you call `relu` here.]

## Poirot's Tracer

Poirot de-abstracts Julia code in a way that can be considered similar to Python
tracing systems like [Jax](https://github.com/google/jax). For example:

```julia
julia> using Poirot.Abstract: @trace

julia> function pow(x, n)
         r = 1
         while n > 0
           n -= 1
           r *= x
         end
         return r
       end

julia> @trace pow(Float64, 3)
1: (%1 :: const(pow), %2 :: Float64, %3 :: const(3))
  %4 = (*)(1, %2) :: Float64
  %5 = (*)(%4, %2) :: Float64
  %6 = (*)(%5, %2) :: Float64
  return %6
```

This fragment of IR is roughly equivalent to a 'Jaxpr', in Jax terminology, or
'Wengert List' or 'Computational Graph'; essentially a very explicit, primitive
representation of source code where variables are named like `%2`. Because we
know `n` in advance we can unroll the loop; more generally, if we know enough to
see what all control flow would do, we can eliminate all of it from the final
trace.

In fact, if we know enough about the inputs we can get rid of most of the
program.

```julia
julia> @trace pow(2, 3)
1: (%1 :: const(pow), %2 :: const(2), %3 :: const(3))
  return 8
```

However, there's a twist. What happens if we don't know `n`?

```julia
julia> @trace pow(Int, Int)
1: (%1 :: const(pow), %2 :: Int64, %3 :: Int64)
  %4 = (>)(%3, 0) :: Bool
  br 3 (1) unless %4
  br 2 (%3, 1)
2: (%5 :: Int64, %6 :: Int64)
  %7 = (-)(%5, 1) :: Int64
  %8 = (*)(%6, %2) :: Int64
  %9 = (>)(%7, 0) :: Bool
  br 3 (%8) unless %9
  br 2 (%7, %8)
3: (%10 :: Int64)
  return %10
```

In this case, we still unroll as much as we can, and if we hit an ambiguous
branch, we just include it. (In this representation, control flow like `if` and
`while` is represented by branches like `br n (x)`. This is like a goto that
jumps to label `n` with `x` as an argument.)

[`pow` doesn't yet work with XLA, since lowering loops into XLA IR is it's own
fun little game. See [XLATools](https://github.com/MikeInnes/XLATools.jl) for
more on that.]

```julia
julia> @trace relu(Int)
1: (%1 :: const(relu), %2 :: Int64)
  %3 = (>)(%2, 0) :: Bool
  br 2 unless %3
  br 3 (%2)
2:
  br 3 (0)
3: (%4 :: Int64)
  return %4
```

To support this kind of thing there are currently two broad approaches:

1. Tracing (like Jax). This has the benefit of being completely reliable; if
your Python code doesn't error then you'll get a really fast and easy to
optimise trace that can run on TPUs and so on. However, tracing
struggles with [control
flow](https://jax.readthedocs.io/en/latest/notebooks/Common_Gotchas_in_JAX.html#%F0%9F%94%AA-Control-Flow)
and [complex code](https://github.com/google/jax/issues/2048), can be
unintuitive with respect to side effects, and can lead to code blowup issues.
Basically, it's hard to maintain the illusion that you're working in one
language, rather than metaprogramming a DSL.

2. Type inference (like Julia or Swift). This is very general and very native,
making feel of the language completely consistent. But even type systems
designed for performance aren't able to optimise as well as partial evaluation,
and tiny amounts of imperfection can blow up when doing things like nested AD.
There are a number of difficult semantic challenges for general-purpose
languages: for example, changes to mutable data structures are supposed to be
visible across threads, meaning you can never elide a simple config dictionary,
and this might make XLA compilation impossible when it should be trivial.

Putting a tracing-like approach in the compiler leads to a kind of hybrid
abstract interpretation / partial evaluation system (the difference between the
two being whether they handle branches as always or never ambiguous). This gives
us a bunch of fine-grained levers with which to make semantic and performance
tradeoffs. There's no good reason to, say, run all `print` statements at
compile time, so let's just not do that.

If we can come up with minimal, convenient semantic tradeoffs that help
performance, we can get the same results as a tracer (where a tracer would work
at all), while getting close-to-optimal results for more complex code (e.g. with
control flow) and retain most of the other semantics of the original language
(e.g. debuggers and stack traces); bringing the ML world much closer to "it's
just code" without the difficult tradeoffs.

## Assumptions of the tracer

The assumption Poirot makes is actually surprisingly minimal. We borrow it from
the world of tracing, which effectively disregards mutation as a part of program
semantics. We can make this a bit more precise by imagining that before running
an `xla` or `infer` block, we take a deepcopy of the whole environment; so you
can only communicate with that block via normal inputs and outputs and explicit
I/O (channels).

In control-flow-free code this assumption will mean that no data structure
operations will turn up in the trace. It turns out that this is _also_ true in
code with control flow, since we can just infer data structure slots as if they
were local variables (with some additional challenges). Just like in Jax this
means we can elide those data structures and make things like XLA compilation
possible.

```julia
julia> function updatezero!(env)
         if env[:x] < 0
           env[:x] = 0
         end
       end

julia> function relu(x)
         env = Dict()
         env[:x] = x
         updatezero!(env)
         return env[:x]
       end

julia> @trace relu(Int)
1: (%1 :: const(relu), %2 :: Int64)
  %3 = (<)(%2, 0) :: Bool
  br 3 (%2) unless %3
  br 2
2:
  br 3 (0)
3: (%4 :: Int64)
  return %4

julia> xla(() -> relu(5))
5

julia> xla(() -> relu(-5))
0
```

[It may be possible to make this even nicer by seeing the block as a
_transaction_, i.e.  mutations are visible but are committed atomically once the
block is done running. Modern views on state and change developed primarily by
the functional and the database communities have a lot to offer the ML
engineering world. This is effectively how Julia makes changes to runtime state
(method redefinition) work, too.]
