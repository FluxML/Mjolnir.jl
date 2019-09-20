using Poirot, IRTools, Test
using Poirot: Const, Partial, interpreter, run!, return_type
using IRTools: var

ir = @code_ir identity(1)
@test return_type(ir, nothing, Int) == Int

add(a, b) = a+b

ir = @code_ir add(1, 2)

it = interpreter(ir, nothing, Const(1.0), Const(2))
@test run!(it) == Const(3.0)
@test it.env[var(4)] == Const(3.0)

it = interpreter(ir, nothing, Int, Const(2.0))
@test run!(it) == Float64
@test it.env[var(4)] == Float64

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
it = interpreter(ir, nothing, Int64, Const(5))
@test run!(it) == Int64
