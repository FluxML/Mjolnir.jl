module Poirot

using Reexport, Printf, IRTools.All, QuadGK
@reexport using Distributions
@reexport using Statistics
using MacroTools: @forward

export Rejection
export infer, observe, @code_xla

include("abstract/Abstract.jl")
using .Abstract

include("lax/LAX.jl")
using .LAX

include("compiler/simplify.jl")
include("compiler/logprob.jl")

include("inference/distributions.jl")
include("inference/inference.jl")
include("inference/trivial.jl")
include("inference/quad.jl")
include("inference/rejection.jl")

end # module
