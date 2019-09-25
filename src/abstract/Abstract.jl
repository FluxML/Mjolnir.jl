module Abstract

using IRTools
using IRTools: IR, CFG, Variable, block, blocks, arguments, argtypes, isexpr,
  stmt, branches, isreturn, returnvalue, argument!, return!

include("utils.jl")
include("interpreter.jl")
include("trace.jl")
include("base.jl")

end
