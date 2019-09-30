using .Abstract: AType, @trace, abstract

struct ConditionError end

function observe(result::Bool)
  result || throw(ConditionError())
  return
end

Abstract.abstract(::AType{typeof(observe)}, ::AType{Bool}) = Nothing

function infer(f)
  alg = Rejection()
  infer(f, alg)
end
