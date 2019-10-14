using Poirot.Abstract, IRTools, Test
using Poirot.Abstract: Const, Partial, Inference, return_type, @trace, exprtype, returntype
using IRTools: var, returnvalue

ir = @code_ir identity(1)
@test return_type(ir, Nothing, Int) == Int

add(a, b) = a+b

ir = @code_ir add(1, 2)

@test return_type(ir, Nothing, Const(1.0), Const(2)) == Const(3.0)

@test return_type(ir, Nothing, Int, Const(2.0)) == Float64

g = 2
addg(x) = x+g
ir = @code_ir addg(2)
@test return_type(ir, Nothing, Const(2)) == Const(4)
@test return_type(ir, Nothing, Float64) == Float64

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

tr = @trace pow(Int, 3)
@test length(tr.blocks) == 1
@test returntype(tr) == Int

tr = @trace pow(2, 3)
@test length(tr.blocks) == 1
@test returntype(tr) == Const(8)

tr = @trace pow(2, Int)
@test returntype(tr) == Int

tr = @trace pow(2.0, Int)
@test returntype(tr) == Union{Float64,Int}

tr = @trace pow(1, Int)
@test returntype(tr) == Const(1)

tr = @trace bar(Int, Int)
@test returntype(tr) == Int

function foo(x)
  r = Ref{Any}()
  r[] = x
  return r[]
end

tr = @trace foo(1)
@test returntype(tr) == Const(1)

tr = @trace foo(Int)
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

tr = @trace pow(Int, Int)
@test returntype(tr) == Int
