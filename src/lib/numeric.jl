@pure Defaults +, -, *, /, &, |, ^, !, >, >=, <, <=, ==, !=, sin, cos, tan, float

abstract(::Defaults, ::AType{typeof(===)}, a::Const{T}, b::Const{T}) where T =
  Const(a.value === b.value)

abstract(::Defaults, ::AType{typeof(===)}, a::AType{T}, b::AType{T}) where T = Bool
abstract(::Defaults, ::AType{typeof(===)}, a, b) = Const(false)

abstract(::Defaults, ::AType{typeof(rand)}) = Float64
abstract(::Defaults, ::AType{typeof(randn)}) = Float64
abstract(::Defaults, ::AType{typeof(rand)}, ::AType{<:Type{Bool}}) where T = Bool
