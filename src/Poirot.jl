module Poirot

export Sample, Rejection, ABC

include("abstract/utils.jl")
include("abstract/interpreter.jl")
include("abstract/base.jl")

include("distributions.jl")

include("inference/rejection.jl")
include("inference/abc.jl")

end # module
