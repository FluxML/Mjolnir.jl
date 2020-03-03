# Mjolnir

[![Build Status](https://travis-ci.org/MikeInnes/Mjolnir.jl.svg?branch=master)](https://travis-ci.org/MikeInnes/Mjolnir.jl)

```julia
julia> using Mjolnir

julia> function pow(x, n)
         r = 1
         while n > 0
           n -= 1
           r *= x
         end
         return r
       end
pow (generic function with 1 method)

julia> @trace pow(Int, 3)
1: (%1 :: const(pow), %2 :: Int64, %3 :: const(3))
  %4 = (*)(1, %2) :: Int64
  %5 = (*)(%4, %2) :: Int64
  %6 = (*)(%5, %2) :: Int64
  return %6

julia> @trace pow(3, Int)
1: (%1 :: const(pow), %2 :: const(3), %3 :: Int64)
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
  %4 = (println)("r = ", "2")
  %5 = (println)("r = ", "4")
  %6 = (println)("r = ", "8")
  return 8

julia> function updatezero!(env)
         if env[:x] < 0
           env[:x] = 0
         end
       end
updatezero! (generic function with 1 method)

julia> function relu2(x)
         env = Dict()
         env[:x] = x
         updatezero!(env)
         return env[:x]
       end
relu2 (generic function with 1 method)

julia> @trace relu2(Int)
1: (%1 :: const(relu2), %2 :: Int64)
  %3 = (<)(%2, 0) :: Bool
  br 3 unless %3
  br 2
2:
  br 4 (0)
3:
  br 4 (%2)
4: (%4 :: Int64)
  return %4
```
