using Distributions

abstract(::AType{typeof(rand)}) = Float64
abstract(::AType{typeof(randn)}) = Float64
abstract(::AType{typeof(rand)}, ::AType{Uniform{T}}) where T = T
abstract(::AType{typeof(rand)}, ::AType{Normal{T}}) where T = T
abstract(::AType{typeof(rand)}, ::AType{<:Bernoulli}) where T = Bool
abstract(::AType{typeof(rand)}, ::AType{<:Type{Bool}}) where T = Bool
