module Poirot

using Reexport, Printf
@reexport using Distributions
@reexport using Statistics
using MacroTools: @forward

export Rejection
export infer, observe

include("abstract/Abstract.jl")
using .Abstract

include("inference/empirical.jl")
include("inference/inference.jl")
include("inference/rejection.jl")

end # module
