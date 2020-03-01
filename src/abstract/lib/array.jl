arrayshape(::Type{Array{T,N}}, sz...) where {T,N} =
  Partial{Array{T,N}}(convert(Array{Any}, fill(T, sz)))

PartialArray{T,N} = Partial{Array{T,N}}

arrayshape(T::Type, sz...) = arrayshape(Array{T,length(sz)}, sz...)

abstract(::AType{typeof(eltype)}, T::Const) = Const(eltype(T.value))

abstract(::AType{typeof(length)}, xs::PartialArray) = Const(length(xs.value))

partial(::AType{typeof(getindex)}, xs::PartialArray, i::Const...) =
  xs.value[map(i -> i.value, i)...]

abstract(::AType{Colon}, xs::Const...) =
  Const(Colon()(map(x -> x.value, xs)...))

abstract(::AType{typeof(*)}, ::AType{A}, b::AType{B}) where {A<:AbstractArray{<:Number}, B<:AbstractArray{<:Number}} =
  Core.Compiler.return_type(*, Tuple{A, B})

abstract(::AType{typeof(+)}, ::AType{A}, b::AType{B}) where {A<:AbstractArray{<:Number}, B<:AbstractArray{<:Number}} =
  Core.Compiler.return_type(+, Tuple{A, B})
