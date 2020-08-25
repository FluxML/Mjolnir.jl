# Types and Primitives

## Types

Mjolnir extends Julia's type system with three new types-of-types, `Const`,
`Shape` and `Partial`. `Const` represents known constants, `Partial` represents
partially-known composites like structs and tuples, and `Shape` represents an
array where the size is known. All of these types are instances of `AType`, so
you can use e.g. `AType{<:Integer}` where normally you'd use `Type{<:Integer}`,
for example.

`Const` is the most important. Remembering that types represent the set of
values a variable can take on at runtime,<sup>1</sup> `Const` just represents
the set of one value. A function that takes `Const` inputs can be evaluated
ahead of time and removed from the trace; if we know a boolean condition is
`Const`, we can unroll loops and elide branches of `if` statements (both of
which are equivalent to function monomorphisation / inlining in Mjolnir).

```julia
julia> function pow(x, n)
         r = 1
         while n > 0
           n -= 1
           r *= x
         end
         return r
       end

julia> using Mjolnir: Defaults, Const, trace

julia> trace(Defaults(), typeof(pow), Int, Const(3))
1: (%1 :: typeof(pow), %2 :: Int64, %3 :: const(3))
  %4 = (*)(1, %2) :: Int64
  %5 = (*)(%4, %2) :: Int64
  %6 = (*)(%5, %2) :: Int64
  return %6
```

## Primitives

When tracing a function `f`, we generally recurse into functions that `f` calls
(like `^` in the example below). This can't, of course, go on forever; Mjolnir
stops at functions like `*` and just knows what type they'll return. These
functions are called _primitives_.

```julia
julia> f(x) = 3x^2 + 2x + 1
f (generic function with 1 method)

julia> @trace f(::Int)
1: (%1 :: const(f), %2 :: Int64)
  %3 = (*)(%2, %2) :: Int64
  %4 = (*)(3, %3) :: Int64
  %5 = (*)(2, %2) :: Int64
  %6 = (+)(%4, %5, 1) :: Int64
  return %6
```

The mechanism for this is what we call a _primitive set_. One primitive set is
`Mjolnir.Defaults()`, which is what `@trace` uses by default. To decide whether
to treat something as primitive, we use the function `abstract`:

```julia
julia> abstract(Defaults(), typeof(f), Int)

julia> abstract(Defaults(), typeof(+), Int, Int)
Int64

julia> abstract(Defaults(), typeof(+), Const(1), Const(2))
const(3)
```

`abstract` takes a primitive set and a method signature (the type of a function
and its arguments), and returns either (a) a return type, if the function is
primitive, or (b) `nothing`, if Mjolnir should carry on tracing into this
function. Notice that here Mjolnir traces into `f` but not `+`.

To customise Mjolnir's behaviour, we can just override `abstract` for the
function we're interested in.

```julia
julia> using Mjolnir; using Mjolnir: Basic, AType, Const, abstract

julia> foo(x) = error("not actually implemented");

julia> Mjolnir.abstract(::Basic, ::AType{typeof(foo)}, x) = (@show x; Int)

julia> f(x) = foo(x)
f (generic function with 1 method)

julia> @trace f(1)
x = const(1)
1: (%1 :: const(foo), %2 :: const(1))
  %3 = (foo)(1) :: Int
  return %3
```

(We can't override `Defaults`, which is actually a composite set of primitives – see below – so we use `Mjolnir.Basics` for now.) Notice that during trace time, `x` (a type) was printed. Mjolnir provides the `@abstract` macro which makes overrides a bit easier.

```julia
julia> using Mjolnir: @abstract

julia> @abstract Basic foo(x::Int) = Int
```

Remember that abstract functions behave a bit like generated functions; even though we wrote `x::Int` here, `x` will be a _type_ in the function body.

`Const`, `Shape` and `Partial` are special type names when writing an `@abstract` function, so we can dispatch on what kind of type we have. For example, perhaps we know that when called with an integer `x`, `foo` will return `x+1`.

```julia
julia> @abstract Basic foo(x::Const{Int}) = Const(x.value+1)

julia> @trace f(1)
1: (%1 :: const(f), %2 :: const(1))
  return 2
```

## Primitive Sets

Not every application needs to see the same set of primitives. For example, a
differentiation engine might be happy to treat `Number * Number` as a primitives
(the gradient is the same regardless of the type). A compiler might only want
`Int64 * Int64` and `Float64 * Float64` to be primitive, with `Int64 * Float64`
being traced to insert the correct conversions. For this reason, primitive sets
are designed to be customised and reused.

Here's a quick example of this behaviour. We drop `Mjolnir.Defaults`, which
treats `Number * Number` as a primitive, in favour of our own version
`MyPrimitives`. However, we almost certainly want to use the `Mjolnir.Basic` set
which defines primitives around basic data structures and other core operations.
We therefore combine `MyPrimitives` and `Mjolnir.Basic` with `Multi`, which
checks multiple primitive sets and returns the first match it finds.

```julia
julia> using Mjolnir: Multi, AType, Const, @abstract

julia> struct MyPrimitives end

julia> @abstract MyPrimitives Float64(x::Integer) = Float64

julia> @abstract MyPrimitives a::Const + b::Const = Const(a.value + b.value)

julia> @abstract MyPrimitives (a::AType{T} * b::AType{T}) where T<:Union{Float64,Int64} = T

julia> MyDefaults() = Multi(MyPrimitives(), Mjolnir.Basic())

julia> @trace MyDefaults() ::Int * ::Float64
1: (%1 :: const(*), %2 :: Int64, %3 :: Float64)
  %4 = ($(QuoteNode(Float64)))(%2) :: Float64
  %5 = (*)(%4, %3) :: Float64
  return %5
```

<sup>1</sup>We can actually flip this around and say that constant propagation,
rather than type inference, is all you need: constant prop of data type tags is
equivalent to type inference, constant shapes get us shape analysis, propagating
ref counts gets us escape analysis, etc.
