module Poirot

export Sample, Rejection, ABC

include("abstract/Abstract.jl")
using .Abstract

include("distributions.jl")

include("inference/rejection.jl")
include("inference/abc.jl")

end # module
