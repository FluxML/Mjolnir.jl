arrayshape(::Type{Array{T,N}}, sz...) where {T,N} =
  Partial{Array{T,N}}(convert(Array{Any}, fill(T, sz)))

arrayshape(T::Type, sz...) = arrayshape(Array{T,length(sz)}, sz...)

abstract(::Defaults, ::AType{typeof(getindex)}, xs::Const{<:Array}, i::Const...) =
  Const(xs.value[map(i -> i.value, i)...])

PartialArray{T,N} = Partial{Array{T,N}}

abstract(::Defaults, ::AType{typeof(length)}, xs::PartialArray) = Const(length(xs.value))

abstract(::Defaults, ::AType{typeof(eltype)}, xs::AType{<:AbstractArray{T}}) where T = T

partial(::Defaults, ::AType{typeof(getindex)}, xs::PartialArray, i::Const...) =
  xs.value[map(i -> i.value, i)...]

@pure Defaults Colon(), length

abstract(::Defaults, ::AType{typeof(Broadcast.broadcasted)}, f, args...) =
  Core.Compiler.return_type(broadcast, Tuple{widen(f),widen.(args)...})

using NNlib

@pure Defaults softmax, Core.kwfunc(softmax)
