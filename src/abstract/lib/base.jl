abstract(::AType{typeof(getfield)}, m::Const{Module}, f::Const{Symbol}) =
  Const(getfield(m.value, f.value))

abstract(::AType{typeof(Core.apply_type)}, Ts::Const...) =
  Const(Core.apply_type(map(T -> T.value, Ts)...))

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
