arrayshape(::Type{Array{T,N}}, sz...) where {T,N} =
  Partial{Array{T,N}}(convert(Array{Any}, fill(T, sz)))

arrayshape(T::Type, sz...) = arrayshape(Array{T,length(sz)}, sz...)

@abstract Basic getindex(xs::Const{<:Array}, i::Const...) =
  Const(xs.value[map(i -> i.value, i)...])

@abstract Basic length(xs::Const{<:Array}) = Const(length(xs.value))
@abstract Basic length(xs::Partial{<:Array}) = Const(length(xs.value))
@abstract Basic length(xs::Shape{<:Array}) = Const(prod(size(xs)))
@abstract Basic length(xs::Array) = Int

@abstract Basic size(xs::Const) = Const(size(xs.value))
@abstract Basic size(xs::Const{Array{T,N}}) where {T,N} = Const(size(xs.value))
@abstract Basic size(xs::Partial{<:Array}) = Const(size(xs.value))
@abstract Basic size(xs::Shape{Array{T,N}}) where {T,N} = Const(size(xs))
@abstract Basic size(xs::AType{Array{T,N}}) where {T,N} = NTuple{N,Int}
@abstract Basic size(xs::AType{Array{T,N}}, i::Const) where {T,N} = i.value > N ? Const(1) : Const(size(xs)[i.value])

@abstract Basic eltype(xs::AbstractArray{T}) where T = Const(T)

@partial Basic getindex(xs::Partial{<:Array}, i::Const...) =
  xs.value[map(i -> i.value, i)...]

@abstract Basic Vector{Any}() = Partial{Vector{Any}}([])

@partial Basic push!(xs::Partial{Vector{T}}, x::T) where T = (push!(xs.value, x); xs)

@partial Basic pop!(xs::Partial{Vector{T}}) where T = pop!(xs.value)

@abstract Basic collect(xs::Const{<:Tuple}) = Const(collect(xs.value))

@pure Basic Colon(), similar, Broadcast.BroadcastStyle, Broadcast.result_style

@abstract Basic map(xs::Const...) = Const(map([x.value for x in xs]...))

@abstract Basic function Broadcast.broadcasted(::Broadcast.AbstractArrayStyle, f, args...)
  A = Core.Compiler.return_type(broadcast, Tuple{widen(f),widen.(args)...})
  if f isa Const && args isa Tuple{Vararg{Const}}
    return Const(broadcast(f.value, map(x -> x.value, args)...))
  elseif args isa Tuple{Vararg{Union{Const,Shape,AType{<:Number}}}} && !(args isa Tuple{Vararg{AType{<:Number}}})
    return Shape{A}(Broadcast.broadcast_shape(size.(args)...))
  else
    return A
  end
end

@abstract Basic function mapreduce(f, op, A; dims = :)
  T = Core.Compiler.return_type(mapreduce, Tuple{widen(f),widen(op),widen(A)})
  (dims == Const(:) || dims == (:)) && return T
  A isa Type && return A
  return Shape{Array{eltype(T),ndims(A)}}(ntuple(i -> i in dims ? 1 : size(A)[i], ndims(A)))
end
