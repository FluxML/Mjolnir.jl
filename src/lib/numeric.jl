struct Numeric end

@pure Numeric +, -, *, /, &, |, ^, !, >, >=, <, <=, ==, !=, sin, cos, tan, float

@abstract Numeric rand() = Float64
@abstract Numeric randn() = Float64
@abstract Numeric rand(::AType{<:Type{Bool}}) where T = Bool
