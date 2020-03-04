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

function partial(::Defaults, ::Const{typeof(__new__)}, ::AType{Type{T}}, xs...) where T
  Partial{T}(Any[i > length(xs) ? Union{} : xs[i] for i in 1:length(fieldnames(T))])
end

partial(::Defaults, ::Const{typeof(__new__)}, t::AType{Type{T}}, xs::Const...) where T =
  abstract(Defaults(), Const(__new__), t, xs...)

function abstract(::Defaults, ::Const{typeof(__new__)}, ::AType{Type{T}}, xs::Const...) where T
  if T.mutable
    Partial{T}(Any[i > length(xs) ? Union{} : xs[i] for i in 1:length(fieldnames(T))])
  else
    Const(__new__(T, map(x -> x.value, xs)...))
  end
end

function partial(::Defaults, ::AType{typeof(__splatnew__)}, ::AType{Type{T}}, xs::Const{<:Tuple}) where T
  Partial{T}(Const.(xs.value))
end

abstract(::Defaults, ::Const{typeof(tuple)}, xs::Type...) = Tuple{xs...}

abstract(::Defaults, ::Const{typeof(tuple)}, xs...) = ptuple(xs...)

abstract(::Defaults, ::AType{typeof(getindex)}, x::Const{<:Tuple}, i::Const{<:Integer}) =
  Const(x.value[i.value])

abstract(::Defaults, ::AType{typeof(getindex)}, x::Partial{<:Tuple}, i::Const{<:Integer}) =
  x.value[i.value]

abstract(::Defaults, ::AType{typeof(length)}, xs::Partial{<:Tuple}) = Const(length(xs.value))

function partial(::Defaults, ::AType{typeof(setfield!)}, x::Partial{T}, name::Const{Symbol}, s) where T
  i = findfirst(f -> f == name.value, fieldnames(T))
  x.value[i] = s
  x
end

function partial(::Defaults, ::AType{typeof(getfield)}, x::Partial{T}, name::Const{Symbol}) where T
  i = findfirst(f -> f == name.value, fieldnames(T))
  x.value[i]
end

function partial(::Defaults, ::AType{typeof(getfield)}, x::Partial{T}, i::Const{<:Integer}) where T
  x.value[i.value]
end

function partial(::Defaults, ::AType{typeof(getfield)}, x::Const{T}, i::Const{<:Integer}) where T
  Const(x.value[i.value])
end

partial(::Defaults, ::AType{typeof(getfield)}, x::Const, name::Const{Symbol}) =
  Const(getfield(x.value, name.value))

function mutate(::Defaults, cx::MutCtx, ::AType{typeof(setfield!)}, x::Partial{T}, name::Const{Symbol}, s) where T
  i = findfirst(f -> f == name.value, fieldnames(T))
  S = x.value[i]
  if !_issubtype(s, S)
    x.value[i] = _union(S, s)
    visit!(cx, x)
  end
  x
end

function mutate(::Defaults, cx::MutCtx, ::AType{typeof(getfield)}, x::Partial{T}, name) where T
  edge!(cx, x)
  i = findfirst(f -> f == name.value, fieldnames(T))
  x.value[i]
end

# Dictionaries

partial(::Defaults, ::AType{Type{Dict}}) = Partial{Dict{Any,Any}}(Dict())

function partial(::Defaults, ::AType{typeof(setindex!)}, x::Partial{Dict{K,V}}, s::AType{<:V}, name::Const{<:K}) where {K,V}
  x.value[name.value] = s
  x
end

function partial(::Defaults, ::AType{typeof(getindex)}, x::Partial{Dict{K,V}}, name::Const{<:K}) where {K,V}
  x.value[name.value]
end

function mutate(::Defaults, cx::MutCtx, ::AType{typeof(setindex!)}, x::Partial{Dict{K,V}}, s::AType{<:V}, name::Const{<:K}) where {K,V}
  T = get(x.value, name.value, Union{})
  if !_issubtype(s, T)
    visit!(cx, x)
    x.value[name.value] = _union(T, s)
  end
  return x
end

function mutate(::Defaults, cx::MutCtx, ::AType{typeof(getindex)}, x::Partial{Dict{K,V}}, name::Const{<:K}) where {K,V}
  edge!(cx, x)
  get(x.value, name.value, Union{})
end
