struct Numeric end

@pure Numeric +, -, *, /, &, |, ^, !, >, >=, <, <=, ==, !=, sin, cos, tan, float

@abstract Numeric rand() = Float64
@abstract Numeric randn() = Float64
@abstract Numeric rand(::Type{Bool}) where T = Bool

@abstract Numeric sum(xs::Array{T,N}; dims = :) where {T,N} =
  dims == Const(:) ? T : Array{T,N}
