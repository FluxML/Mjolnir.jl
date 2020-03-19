module Mjolnir

using IRTools, MacroTools
using IRTools.All
using IRTools: block

export @trace

include("context.jl")
include("cleanup.jl")
include("infer.jl")
include("trace.jl")
include("macros.jl")

include("lib/base.jl")
include("lib/numeric.jl")
include("lib/array.jl")
include("lib/struct.jl")

end # module
