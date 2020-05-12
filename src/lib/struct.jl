@generated function __new__(T, args...)
  quote
    Base.@_inline_meta
    $(Expr(:new, :T, [:(args[$i]) for i = 1:length(args)]...))
  end
end

@generated function __splatnew__(T, args)
  quote
    Base.@_inline_meta
    $(Expr(:splatnew, :T, :args))
  end
end

@partial Basic function __new__(::Type{T}, xs...) where T
  Partial{T}(Any[i > length(xs) ? Union{} : xs[i] for i in 1:length(fieldnames(T))])
end

@partial Basic __new__(t::Type{T}, xs::Const...) where T =
  abstract(Basic(), Const(__new__), t, xs...)

@abstract Basic function __new__(::Type{T}, xs::Const...) where T
  if T.mutable
    Partial{T}(Any[i > length(xs) ? Union{} : xs[i] for i in 1:length(fieldnames(T))])
  else
    Const(__new__(T, map(x -> x.value, xs)...))
  end
end

@partial Basic function __splatnew__(::Type{T}, xs::Const{<:Tuple}) where T
  Const(__splatnew__(T, xs.value))
end

@partial Basic function __splatnew__(::Type{T}, xs::Partial{<:Tuple}) where T
  Partial{T}(Any[i > length(xs.value) ? Union{} : xs.value[i] for i in 1:length(fieldnames(T))])
end

abstract(::Basic, ::AType{typeof(tuple)}, xs::Type...) = Tuple{xs...}

@abstract Basic tuple(xs...) = ptuple(xs...)

@abstract Basic getindex(x::Const{<:Tuple}, i::Const{<:Integer}) =
  Const(x.value[i.value])

@abstract Basic getindex(x::Partial{<:Tuple}, i::Const{<:Integer}) =
  x.value[i.value]

@abstract Basic getindex(xs::Tuple, i::Const{<:Integer}) = widen(xs).parameters[i.value]

@abstract Basic length(xs::Partial{<:Tuple}) = Const(length(xs.value))

@partial Basic function setfield!(x::Partial{T}, name::Const{Symbol}, s) where T
  i = findfirst(f -> f == name.value, fieldnames(T))
  x.value[i] = s
  x
end

@partial Basic function getfield(x::Partial{T}, name::Const{Symbol}) where T
  i = findfirst(f -> f == name.value, fieldnames(T))
  x.value[i]
end

@partial Basic function getfield(x::Partial{T}, i::Const{<:Integer}) where T
  x.value[i.value]
end

@partial Basic function getfield(x::Const{T}, i::Const{<:Integer}) where T
  Const(x.value[i.value])
end

@partial Basic getfield(x::Const, name::Const{Symbol}) =
  Const(getfield(x.value, name.value))

function mutate(::Basic, cx::MutCtx, ::AType{typeof(setfield!)}, x::Partial{T}, name::Const{Symbol}, s) where T
  i = findfirst(f -> f == name.value, fieldnames(T))
  S = x.value[i]
  if !_issubtype(s, S)
    x.value[i] = _union(S, s)
    visit!(cx, x)
  end
  x
end

function mutate(::Basic, cx::MutCtx, ::AType{typeof(getfield)}, x::Partial{T}, name) where T
  edge!(cx, x)
  i = findfirst(f -> f == name.value, fieldnames(T))
  x.value[i]
end

# Dictionaries

@partial Basic Dict() = Partial{Dict{Any,Any}}(Dict())

@partial Basic function setindex!(x::Partial{Dict{K,V}}, s::V, name::Const{<:K}) where {K,V}
  x.value[name.value] = s
  x
end

@partial Basic function getindex(x::Partial{Dict{K,V}}, name::Const{<:K}) where {K,V}
  x.value[name.value]
end

function mutate(::Basic, cx::MutCtx, ::AType{typeof(setindex!)}, x::Partial{Dict{K,V}}, s::AType{<:V}, name::Const{<:K}) where {K,V}
  T = get(x.value, name.value, Union{})
  if !_issubtype(s, T)
    visit!(cx, x)
    x.value[name.value] = _union(T, s)
  end
  return x
end

function mutate(::Basic, cx::MutCtx, ::AType{typeof(getindex)}, x::Partial{Dict{K,V}}, name::Const{<:K}) where {K,V}
  edge!(cx, x)
  get(x.value, name.value, Union{})
end

@abstract Basic (==)(a::Const, b::Const) = Const(a.value == b.value)
@abstract Basic (==)(a, b) = Bool

@abstract Basic (!=)(a::Const, b::Const) = Const(a.value != b.value)
@abstract Basic (!=)(a, b) = Bool

@abstract Basic (===)(a::Const{T}, b::Const{T}) where T =
  Const(a.value === b.value)

@abstract Basic (===)(a::AType{T}, b::AType{T}) where T = Bool
@abstract Basic (===)(a, b) = Const(false)

@abstract Basic isempty(x::Const) = Const(isempty(x.value))
