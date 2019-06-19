using Reexport
@reexport using Distributions

struct Sample{T}
  data::Vector{T}
end
