using Mjolnir, IRTools, Test
using Mjolnir: Const, Partial, Inference, return_type, @trace, exprtype,
  returntype, arrayshape
using IRTools: var, returnvalue, blocks

ir = @code_ir identity(1)
@test return_type(ir, Nothing, Int) == Int

add(a, b) = a+b

ir = @code_ir add(1, 2)

@test return_type(ir, Nothing, Const(1.0), Const(2)) == Const(3.0)

@test return_type(ir, Nothing, Int, Const(2.0)) == Float64

f(x...) = +(x...)

tr = @trace f(5, 7)
@test returntype(tr) == Const(12)

tr = @trace Base.tail((1, 2, 3))
@test returntype(tr) == Const((2, 3))

g = 2
addg(x) = x+g
ir = @code_ir addg(2)
@test return_type(ir, Nothing, Const(2)) == Const(4)
@test return_type(ir, Nothing, Float64) == Float64

f() = rand() < 0.5 ? "foo" : "bar"

ir = @code_ir f()
@test return_type(ir, Nothing) == String

function pow(x, n)
  r = 1
  while n > 0
    n -= 1
    r *= x
  end
  return r
end

ir = @code_ir pow(2, 3)
@test return_type(ir, Nothing, Int64, Const(5)) == Int
@test return_type(ir, Nothing, Float64, Int) == Union{Float64, Int}
@test return_type(ir, Nothing, Float64, Const(5)) == Float64
@test return_type(ir, Nothing, Const(2), Const(3)) == Const(8)

foo(a, b) = a + b
bar(a, b) = foo(a, b)

ir = @code_ir bar(1, 1)
@test return_type(ir, Nothing, Int, Int) == Int

fact(n) = n == 0 ? 1 : n*fact(n-1)

ir = @code_ir fact(1)
@test return_type(ir, Nothing, Int) == Int

# Tracing

tr = @trace f()
@test returntype(tr) == String

tr = @trace pow(::Int, 3)
@test length(tr.blocks) == 1
@test returntype(tr) == Int

tr = @trace pow(2, 3)
@test length(tr.blocks) == 1
@test returntype(tr) == Const(8)

tr = @trace pow(2, ::Int)
@test returntype(tr) == Int

tr = @trace pow(2.0, ::Int)
@test returntype(tr) == Union{Float64,Int}

tr = @trace pow(1, ::Int)
@test returntype(tr) == Const(1)

tr = @trace bar(::Int, ::Int)
@test returntype(tr) == Int

function foo(x)
  r = Ref{Any}()
  r[] = x
  return r[]
end

tr = @trace foo(1)
@test returntype(tr) == Const(1)

tr = @trace foo(::Int)
@test returntype(tr) == Int

function foo(x)
  r = Ref{Any}()
  r[] = x
  if rand(Bool)
    r[] = 1
  end
  return r[]
end

tr = @trace foo(1)
@test returntype(tr) == Const(1)

tr = @trace foo(2)
@test returntype(tr) == Int

struct Foo
  x
end

function foo(x)
  r = Foo(x)
  return r.x
end

tr = @trace foo(2)
@test returntype(tr) == Const(2)

foo(x) = Foo(x)

tr = @trace foo(1)
@test returntype(tr) == Const(Foo(1))

function pow(x, n)
  env = Dict()
  env[:r] = 1
  env[:n] = n
  while env[:n] > 0
    env[:r] *= x
    env[:n] -= 1
  end
  return env[:r]
end

tr = @trace pow(2, 3)
@test returntype(tr) == Const(8)

tr = @trace pow(::Int, ::Int)
@test returntype(tr) == Int

function sumabs2(xs)
  s = zero(eltype(xs))
  for i = 1:length(xs)
    s += xs[i]
  end
  return s
end

tr = @trace sumabs2(::arrayshape(Float64, 3))
@test length(blocks(tr)) == 1
@test returntype(tr) == Float64

f(xs) = sum(xs)
tr = @trace f(::Matrix{Int32})
@test returntype(tr) == Int32

f(xs) = sum(xs, dims = 1)
tr = @trace f(::Matrix{Int32})
@test returntype(tr) == Matrix{Int32}


function negsquare(x)
    if x > 0
        return x^2
    else
        return -x^2
    end
end

tr = @trace negsquare(::Float64)
@test returntype(tr) == Float64
