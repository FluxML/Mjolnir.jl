# Mjolnir

[![ColPrac: Contributor's Guide on Collaborative Practices for Community Packages](https://img.shields.io/badge/ColPrac-Contributor's%20Guide-blueviolet)](https://github.com/SciML/ColPrac)
[![Build Status](https://travis-ci.org/MikeInnes/Mjolnir.jl.svg?branch=master)](https://travis-ci.org/MikeInnes/Mjolnir.jl)

Mjolnir is a hybrid approach to partial evaluation / abstract interpretation,
with an implementation in Julia. It can be thought of as a blend of
operator-overloading based tracing (as in JAX, PyTorch Script, staged
programming systems etc.) and dataflow-based abstract interpretation (as in the
type inference systems of Julia, TypeScript and Crystal). It is aimed at package
developers rather than Julia end-users.

Mjolnir can reproduce the compact, linear traces (aka computation graphs or
Wengert lists) of tracing systems.

```julia
julia> function pow(x, n)
         r = 1
         while n > 0
           n -= 1
           r *= x
         end
         return r
       end
pow (generic function with 1 method)

julia> using Mjolnir

julia> @trace pow(Int, 3)
1: (%1 :: const(pow), %2 :: Int64, %3 :: const(3))
  %4 = (*)(1, %2) :: Int64
  %5 = (*)(%4, %2) :: Int64
  %6 = (*)(%5, %2) :: Int64
  return %6
```

However, it avoids several of the downsides of those systems. It supports
arbitrary Julia types (not just 'tensors' but also strings and structs). It
supports value-dependent control flow (as it can encode branches in the trace).
It supports side effects and mutating operators. Functions like `println` don't
have to be evaluated at compile time. It can enforce its assumptions (i.e.
referential transparency) rather than making the user responsible for them, and
can generate diagnostics when there are issues. Mjolnir can thus compile a much
wider range of Julia programs than OO approaches.

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

```julia
julia> function pow(x, n)
         r = 1
         while n > 0
           n -= 1
           r *= x
           @show r
         end
         return r
       end
pow (generic function with 1 method)

julia> @trace pow(2, 3)
1: (%1 :: const(pow), %2 :: const(2), %3 :: const(3))
  %4 = (println)("r = ", "2") :: Nothing
  %5 = (println)("r = ", "4") :: Nothing
  %6 = (println)("r = ", "8") :: Nothing
  return 8
```

Mjolnir is designed to be [highly
customisable](https://github.com/MikeInnes/Mjolnir.jl/blob/master/docs/types.md),
and to give as much control as possible to packages that build on it.
