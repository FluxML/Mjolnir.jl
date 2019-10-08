partial(::AType{Type{Ref{T}}}) where T =
  Partial{Ref{T}}(Ref{AType}())

function partial(::AType{typeof(setindex!)}, R::Partial{<:Ref}, x::AType)
  R.value[] = x
  return R
end

partial(::AType{typeof(getindex)}, R::Partial{<:Ref}) = R.value[]

# TODO: in the abstract interpreter, mutable data should have backedges

abstract(::AType{typeof(getindex)}, R::Partial{<:Ref}) = R.value[]

function abstract(::AType{typeof(setindex!)}, R::Partial{<:Ref}, x::AType)
  R.value[] = _union(R.value[], x)
  return R
end
