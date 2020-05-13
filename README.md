# Mjolnir

[![Build Status](https://travis-ci.org/MikeInnes/Mjolnir.jl.svg?branch=master)](https://travis-ci.org/MikeInnes/Mjolnir.jl)

Mjolnir is a hybrid approach to partial evaluation / abstract interpretation,
with an implementation in Julia. It can be thought of as a blend of
operator-overloading based tracing (as in JAX, PyTorch Script, staged
programming systems etc.) and dataflow-based abstract interpretation, as in the
type inference systems of Julia, TypeScript and Crystal. It is aimed at package
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
supports value-dependent control flow as it can encode branches in the trace.
Side effects do not need to be evaluated at compile time. Mjolnir can thus
compile a much wider range of Julia programs than OO approaches.

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

julia> @trace pow(Int, 3)
1: (%1 :: const(pow), %2 :: Int64, %3 :: const(3))
  %4 = (*)(1, %2) :: Int64
  %5 = (repr)(%4) :: String
  %6 = (println)("r = ", %5) :: Nothing
  %7 = (*)(%4, %2) :: Int64
  %8 = (repr)(%7) :: String
  %9 = (println)("r = ", %8) :: Nothing
  %10 = (*)(%7, %2) :: Int64
  %11 = (repr)(%10) :: String
  %12 = (println)("r = ", %11) :: Nothing
  return %10
```

```julia
julia> @trace pow(Int, Int)
1: (%1 :: const(pow), %2 :: Int64, %3 :: Int64)
  %4 = (>)(%3, 0) :: Bool
  br 4 (1) unless %4
  br 2 (%3, 1)
2: (%5 :: Int64, %6 :: const(1))
  %7 = (-)(%5, 1) :: Int64
  %8 = (*)(%6, %2) :: Int64
  %9 = (repr)(%8) :: Union{}
  %10 = (println)("r = ", %9) :: Union{}
  br 3
3:
  %11 = (>)(%7, 0) :: Union{}
  br 4 (%8) unless %11
  br 2 (%7, %8)
4: (%12 :: const(1))
  return %12
```

Mjolnir is designed to be [highly
customisable](https://github.com/MikeInnes/Mjolnir.jl/blob/master/docs/types.md),
and to give as much control as possible to packages that depend on it.
