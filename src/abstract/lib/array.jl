abstract(::AType{typeof(*)}, ::AType{A}, b::AType{B}) where {A<:AbstractArray{<:Number}, B<:AbstractArray{<:Number}} =
  Core.Compiler.return_type(*, Tuple{A, B})

abstract(::AType{typeof(+)}, ::AType{A}, b::AType{B}) where {A<:AbstractArray{<:Number}, B<:AbstractArray{<:Number}} =
  Core.Compiler.return_type(+, Tuple{A, B})
