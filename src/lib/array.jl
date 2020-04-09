arrayshape(::Type{Array{T,N}}, sz...) where {T,N} =
  Partial{Array{T,N}}(convert(Array{Any}, fill(T, sz)))

arrayshape(T::Type, sz...) = arrayshape(Array{T,length(sz)}, sz...)

abstract(::Basic, ::AType{typeof(getindex)}, xs::Const{<:Array}, i::Const...) =
  Const(xs.value[map(i -> i.value, i)...])

PartialArray{T,N} = Partial{Array{T,N}}

abstract(::Basic, ::AType{typeof(length)}, xs::PartialArray) = Const(length(xs.value))

abstract(::Basic, ::AType{typeof(eltype)}, xs::AType{<:AbstractArray{T}}) where T = T

partial(::Basic, ::AType{typeof(getindex)}, xs::PartialArray, i::Const...) =
  xs.value[map(i -> i.value, i)...]

@pure Basic Colon(), length, size

abstract(::Basic, ::AType{typeof(Broadcast.broadcasted)}, f, args...) =
  Core.Compiler.return_type(broadcast, Tuple{widen(f),widen.(args)...})
