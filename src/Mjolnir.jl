module Mjolnir

using IRTools, MacroTools
using IRTools.All
using IRTools: block

export @trace

include("context.jl")
include("cleanup.jl")
include("flow.jl")
include("trace.jl")
include("lib/base.jl")
include("lib/array.jl")
include("lib/struct.jl")

end # module
