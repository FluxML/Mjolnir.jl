arrayshape(::Type{Array{T,N}}, sz...) where {T,N} =
  Partial{Array{T,N}}(convert(Array{Any}, fill(T, sz)))

arrayshape(T::Type, sz...) = arrayshape(Array{T,length(sz)}, sz...)

@abstract Basic getindex(xs::Const{<:Array}, i::Const...) =
  Const(xs.value[map(i -> i.value, i)...])

PartialArray{T,N} = Partial{Array{T,N}}
ConstArray{T,N} = Const{Array{T,N}}

@abstract Basic length(xs::Const) = Const(length(xs.value))
@abstract Basic length(xs::PartialArray) = Const(length(xs.value))

@abstract Basic eltype(xs::AType{<:AbstractArray{T}}) where T = T

@partial Basic getindex(xs::PartialArray, i::Const...) =
  xs.value[map(i -> i.value, i)...]

@pure Basic Colon(), size

@abstract Basic Broadcast.broadcasted(f, args...) =
  Core.Compiler.return_type(broadcast, Tuple{widen(f),widen.(args)...})

@abstract Basic mapreduce(f, op, A) =
  Core.Compiler.return_type(mapreduce, Tuple{widen(f),widen(op),widen(A)})
