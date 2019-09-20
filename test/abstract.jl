using Poirot, IRTools, Test
using Poirot: Interpreter, interpret

ir = @code_ir identity(1)
@test interpret(ir, nothing, Int) == Int
