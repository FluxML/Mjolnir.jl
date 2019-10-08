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

function partial(::Const{typeof(__new__)}, ::AType{Type{T}}, xs...) where T
  Partial{T}(Any[i > length(xs) ? Union{} : xs[i] for i in 1:length(fieldnames(T))])
end

function partial(::Const{typeof(__new__)}, ::AType{Type{T}}, xs::Const...) where T
  if T.mutable
    Partial{T}(Any[i > length(xs) ? Union{} : xs[i] for i in 1:length(fieldnames(T))])
  else
    Const(__new__(T, map(x -> x.value, xs)...))
  end
end

partial(::AType{typeof(__splatnew__)}, ::AType{<:Type}, xs...) = error(":new not implemented")

function partial(::AType{typeof(setfield!)}, x::Partial{T}, name::Const{Symbol}, s) where T
  i = findfirst(f -> f == name.value, fieldnames(T))
  x.value[i] = s
  x
end

function partial(::AType{typeof(getfield)}, x::Partial{T}, name::Const{Symbol}) where T
  i = findfirst(f -> f == name.value, fieldnames(T))
  x.value[i]
end

partial(::AType{typeof(getfield)}, x::Const, name::Const{Symbol}) =
  Const(getfield(x.value, name.value))

# TODO: in the abstract interpreter, mutable data should have backedges

function abstract(::AType{typeof(setfield!)}, x::Partial{T}, name::Const{Symbol}, s) where T
  i = findfirst(f -> f == name.value, fieldnames(T))
  x.value[i] = _union(x.value[i], s)
  x
end

function abstract(::AType{typeof(getfield)}, x::Partial{T}, name) where T
  i = findfirst(f -> f == name.value, fieldnames(T))
  x.value[i]
end
