using Poirot, IRTools, Test
using Poirot: Const, Partial, interpreter, var, run!, return_type

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
