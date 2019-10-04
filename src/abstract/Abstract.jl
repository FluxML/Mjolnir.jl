module Abstract

using IRTools, MacroTools
using IRTools: IR, CFG, Variable, block, blocks, arguments, argtypes, isexpr,
  stmt, branches, isreturn, returnvalue, argument!, return!

include("utils.jl")
include("flow.jl")
include("trace.jl")
include("lib/base.jl")

end
