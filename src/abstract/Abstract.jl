module Abstract

using IRTools, MacroTools
using IRTools: IR, CFG, Variable, block, blocks, arguments, argtypes, isexpr,
  stmt, branches, isreturn, returnvalue, argument!, return!

abstract(Ts...) = nothing
partial(Ts...) = abstract(Ts...)

include("utils.jl")
include("flow.jl")
include("trace.jl")
include("lib/base.jl")
include("lib/struct.jl")
include("lib/random.jl")

end
