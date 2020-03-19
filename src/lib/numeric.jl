struct Numeric end

@pure Numeric +, -, *, /, &, |, ^, !, >, >=, <, <=, ==, !=, sin, cos, tan, float

abstract(::Numeric, ::AType{typeof(===)}, a::Const{T}, b::Const{T}) where T =
  Const(a.value === b.value)

abstract(::Numeric, ::AType{typeof(===)}, a::AType{T}, b::AType{T}) where T = Bool
abstract(::Numeric, ::AType{typeof(===)}, a, b) = Const(false)

abstract(::Numeric, ::AType{typeof(rand)}) = Float64
abstract(::Numeric, ::AType{typeof(randn)}) = Float64
abstract(::Numeric, ::AType{typeof(rand)}, ::AType{<:Type{Bool}}) where T = Bool
