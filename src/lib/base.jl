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

for op in :[+, -, *, /, &, |, ^].args
  @eval abstract(::Defaults, ::AType{typeof($op)}, ::AType{S}, ::AType{T}) where {S<:Number,T<:Number} =
          promote_type(S, T)
  @eval abstract(::Defaults, ::AType{typeof($op)}, a::Const{<:Number}, b::Const{<:Number}) =
          Const($op(a.value, b.value))
end

for op in :[>, >=, <, <=, ==, !=].args
  @eval abstract(::Defaults, ::AType{typeof($op)}, ::AType{S}, ::AType{T}) where {S<:Number,T<:Number} =
          Bool
  @eval abstract(::Defaults, ::AType{typeof($op)}, a::Const{<:Number}, b::Const{<:Number}) =
          Const($op(a.value, b.value))
end

abstract(::Defaults, ::AType{typeof(===)}, a, b) = Bool
abstract(::Defaults, ::AType{typeof(===)}, a::Const, b::Const) = Const(a.value == b.value)

abstract(::Defaults, ::AType{typeof(==)}, a, b) = Bool
abstract(::Defaults, ::AType{typeof(==)}, a::Const, b::Const) = Const(a.value == b.value)

abstract(::Defaults, ::AType{typeof(float)}, x::Const{<:Number}) = Const(float(x.value))

abstract(::Defaults, ::AType{typeof(convert)}, ::Const{Type{T}}, x::Const{<:Number}) where T<:Number =
  Const(convert(T, x.value))

abstract(::Defaults, ::AType{typeof(typeassert)}, x::Const, T::Const) =
  Const(typeassert(x.value, T.value))

abstract(::Defaults, ::AType{typeof(!)}, x::AType{Bool}) = Bool
abstract(::Defaults, ::AType{typeof(!)}, x::Const{Bool}) = Const(!(x.value))

abstract(::Defaults, ::AType{typeof(repr)}, x) = String
abstract(::Defaults, ::AType{typeof(repr)}, x::Const) = Const(repr(x.value))
abstract(::Defaults, ::AType{typeof(println)}, xs...) = Nothing
abstract(::Defaults, ::AType{typeof(print)}, xs...) = Nothing

abstract(::Defaults, ::AType{typeof(rand)}) = Float64
abstract(::Defaults, ::AType{typeof(randn)}) = Float64
abstract(::Defaults, ::AType{typeof(rand)}, ::AType{<:Type{Bool}}) where T = Bool
