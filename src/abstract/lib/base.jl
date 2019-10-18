abstract(::AType{typeof(getfield)}, m::Const{Module}, f::Const{Symbol}) =
  Const(getfield(m.value, f.value))

abstract(::AType{typeof(Core.apply_type)}, Ts::Const...) =
  Const(Core.apply_type(map(T -> T.value, Ts)...))

abstract(::AType{typeof(typeof)}, x::Const) = Const(widen(x))
abstract(::AType{typeof(typeof)}, x::AType{T}) where T =
  isconcretetype(T) ? Const(T) : Type

abstract(::AType{typeof(fieldtype)}, T::Const{<:Type}, f::Const{Symbol}) =
  Const(fieldtype(T.value, f.value))

for op in :[+, -, *, /].args
  @eval abstract(::AType{typeof($op)}, ::AType{S}, ::AType{T}) where {S<:Number,T<:Number} =
          promote_type(S, T)
  @eval abstract(::AType{typeof($op)}, a::Const{<:Number}, b::Const{<:Number}) =
          Const($op(a.value, b.value))
end

for op in :[>, >=, <, <=, ==, !=].args
  @eval abstract(::AType{typeof($op)}, ::AType{S}, ::AType{T}) where {S<:Number,T<:Number} =
          Bool
  @eval abstract(::AType{typeof($op)}, a::Const{<:Number}, b::Const{<:Number}) =
          Const($op(a.value, b.value))
end

abstract(::AType{typeof(===)}, a, b) = Bool
abstract(::AType{typeof(===)}, a::Const, b::Const) = Const(a.value == b.value)

abstract(::AType{typeof(==)}, a, b) = Bool
abstract(::AType{typeof(==)}, a::Const, b::Const) = Const(a.value == b.value)

abstract(::AType{typeof(float)}, x::Const{<:Number}) = Const(float(x.value))

abstract(::AType{typeof(convert)}, ::Const{Type{T}}, x::Const{<:Number}) where T<:Number =
  Const(convert(T, x.value))

abstract(::AType{typeof(!)}, x::Const{Bool}) = Const(!(x.value))
