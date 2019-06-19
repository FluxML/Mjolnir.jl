module Poirot

export Sample, Rejection, ABC

include("distributions.jl")

include("inference/rejection.jl")
include("inference/abc.jl")

end # module
