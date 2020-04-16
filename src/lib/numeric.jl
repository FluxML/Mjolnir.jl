struct Numeric end

@pure Numeric +, -, *, /, &, |, ^, !, >, >=, <, <=, ==, !=, sin, cos, tan, float

abstract(::Numeric, ::AType{typeof(rand)}) = Float64
abstract(::Numeric, ::AType{typeof(randn)}) = Float64
abstract(::Numeric, ::AType{typeof(rand)}, ::AType{<:Type{Bool}}) where T = Bool
