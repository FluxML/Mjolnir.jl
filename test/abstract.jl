using Poirot.Abstract, IRTools, Test
using Poirot.Abstract: Const, Partial, Inference, return_type, trace
using IRTools: var

ir = @code_ir identity(1)
@test return_type(ir, Nothing, Int) == Int

add(a, b) = a+b

ir = @code_ir add(1, 2)

@test return_type(ir, Nothing, Const(1.0), Const(2)) == Const(3.0)
@test ir[var(4)].type == Const(3.0)

@test return_type(ir, Nothing, Int, Const(2.0)) == Float64
@test ir[var(4)].type == Float64

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
@test return_type(ir, Nothing, Float64, Const(5)) == Union{Float64, Int}
@test_broken return_type(ir, Nothing, Const(2), Const(3)) == Const(8)

foo(a, b) = a + b
bar(a, b) = foo(a, b)

ir = @code_ir bar(1, 1)
@test return_type(ir, Nothing, Int, Int) == Int

fact(n) = n == 0 ? 1 : n*fact(n-1)

ir = @code_ir fact(1)
@test return_type(ir, Nothing, Int) == Int

# Tracing

tr = trace(typeof(pow), Int, Const(3))
@test length(tr.blocks) == 1
@test IRTools.exprtype(tr, IRTools.returnvalue(IRTools.block(tr, 1))) == Int

tr = trace(typeof(pow), Const(2), Const(3))
@test length(tr.blocks) == 1
@test IRTools.exprtype(tr, IRTools.returnvalue(IRTools.block(tr, 1))) == Const(8)
