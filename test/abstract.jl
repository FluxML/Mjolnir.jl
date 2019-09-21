using Poirot, IRTools, Test
using Poirot: Const, Partial, Inference, return_type
using IRTools: var

ir = @code_ir identity(1)
@test return_type(ir, Nothing, Int) == Int

add(a, b) = a+b

ir = @code_ir add(1, 2)

@test return_type(ir, Nothing, Const(1.0), Const(2)) == Const(3.0)
@test ir[var(4)].type == Const(3.0)

@test return_type(ir, nothing, Int, Const(2.0)) == Float64
@test ir[var(4)].type == Float64

g = 2
addg(x) = x+g
ir = @code_ir addg(2)
@test return_type(ir, nothing, Const(2)) == Const(4)
@test return_type(ir, nothing, Float64) == Float64

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
