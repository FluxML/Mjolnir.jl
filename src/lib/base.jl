abstract(::Defaults, ::AType{typeof(getfield)}, m::Const{Module}, f::Const{Symbol}) =
  Const(getfield(m.value, f.value))

abstract(::Defaults, ::AType{typeof(getfield)}, m::AType{T}, f::Const{Symbol}) where T =
  fieldtype(T, f.value)

abstract(::Defaults, ::AType{typeof(Core.apply_type)}, Ts::Const...) =
  Const(Core.apply_type(map(T -> T.value, Ts)...))

abstract(::Defaults, ::AType{typeof(typeof)}, x::Const) = Const(widen(x))
abstract(::Defaults, ::AType{typeof(typeof)}, x::AType{T}) where T =
  isconcretetype(T) ? Const(T) : Type

abstract(::Defaults, ::AType{typeof(fieldtype)}, T::Const{<:Type}, f::Const{Symbol}) =
  Const(fieldtype(T.value, f.value))

abstract(::Defaults, ::AType{typeof(convert)}, ::Const{Type{T}}, x::Const{<:Number}) where T<:Number =
  Const(convert(T, x.value))

abstract(::Defaults, ::AType{typeof(typeassert)}, x::Const, T::Const) =
  Const(typeassert(x.value, T.value))

abstract(::Defaults, ::AType{typeof(rand)}) = Float64
abstract(::Defaults, ::AType{typeof(randn)}) = Float64
abstract(::Defaults, ::AType{typeof(rand)}, ::AType{<:Type{Bool}}) where T = Bool

@pure Defaults +, -, *, /, &, |, ^, !, >, >=, <, <=, ==, !=, ===, sin, cos, tan, float

@pure Defaults repr, println, print, Core.kwfunc, isdefined
