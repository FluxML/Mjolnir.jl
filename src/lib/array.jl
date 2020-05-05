arrayshape(::Type{Array{T,N}}, sz...) where {T,N} =
  Partial{Array{T,N}}(convert(Array{Any}, fill(T, sz)))

arrayshape(T::Type, sz...) = arrayshape(Array{T,length(sz)}, sz...)

@abstract Basic getindex(xs::Const{<:Array}, i::Const...) =
  Const(xs.value[map(i -> i.value, i)...])

@abstract Basic length(xs::Const) = Const(length(xs.value))
@abstract Basic length(xs::Partial{<:Array}) = Const(length(xs.value))
@abstract Basic length(xs::Shape{<:Array}) = Const(prod(size(xs)))

@abstract Basic size(xs::Const) = Const(size(xs.value))
@abstract Basic size(xs::Partial{<:Array}) = Const(size(xs.value))
@abstract Basic size(xs::Shape{<:Array}) = Const(size(xs))

@abstract Basic eltype(xs::AbstractArray{T}) where T = T

@partial Basic getindex(xs::Partial{<:Array}, i::Const...) =
  xs.value[map(i -> i.value, i)...]

@pure Basic Colon()

@abstract Basic Broadcast.broadcasted(::Broadcast.AbstractArrayStyle, f, args...) =
  Core.Compiler.return_type(broadcast, Tuple{widen(f),widen.(args)...})

@abstract Basic mapreduce(f, op, A; dims = :) =
  Core.Compiler.return_type(mapreduce, Tuple{widen(f),widen(op),widen(A)})
