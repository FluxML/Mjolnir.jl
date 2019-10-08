module Abstract

using IRTools, MacroTools
using IRTools.All
using IRTools: block

abstract(Ts...) = nothing
partial(Ts...) = abstract(Ts...)

include("utils.jl")
include("flow.jl")
include("trace.jl")
include("lib/base.jl")
include("lib/struct.jl")
include("lib/random.jl")

end
