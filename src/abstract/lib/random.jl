using Distributions

abstract(::AType{typeof(rand)}) = Float64
abstract(::AType{typeof(randn)}) = Float64
abstract(::AType{typeof(rand)}, ::AType{<:Type{Bool}}) where T = Bool

abstract(::AType{typeof(rand)}, T::AType{<:Distribution}) =
  Core.Compiler.return_type(rand, Tuple{widen(T)})
