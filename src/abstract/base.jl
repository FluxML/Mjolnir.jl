for op in :[+, -, *, /].args
  @eval partial(::AType{typeof($op)}, ::AType{S}, ::AType{T}) where {S<:Number,T<:Number} =
          promote_type(S, T)
  @eval partial(::AType{typeof($op)}, a::Const{<:Number}, b::Const{<:Number}) =
          Const($op(a.value, b.value))
end

for op in :[>, >=, <, <=, ==, !=].args
  @eval partial(::AType{typeof($op)}, ::AType{S}, ::AType{T}) where {S<:Number,T<:Number} =
          Bool
  @eval partial(::AType{typeof($op)}, a::Const{<:Number}, b::Const{<:Number}) =
          Const($op(a.value, b.value))
end
