module Poirot

using Reexport, Printf, IRTools.All
@reexport using Distributions
@reexport using Statistics
using MacroTools: @forward

export Rejection
export infer, observe

include("abstract/Abstract.jl")
using .Abstract

include("compiler/logprob.jl")

include("inference/distributions.jl")
include("inference/inference.jl")
include("inference/trivial.jl")
include("inference/rejection.jl")

end # module
