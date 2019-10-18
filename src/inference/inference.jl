using .Abstract: AType, @trace, abstract, trace

struct ConditionError end

function observe(result::Bool)
  result || throw(ConditionError())
  return
end

Abstract.abstract(::AType{typeof(observe)}, ::AType{Bool}) = Nothing

struct Multi
  algs::Vector{Any}
  Multi(algs...) = new(Any[algs...])
end

function infer(f, m::Multi)
  tr = trace(typeof(f))
  for alg in m.algs
    r = infer(f, alg, tr)
    r == nothing || return r
  end
end

default() = Multi(Trivial(), Quad(), Rejection())

infer(f) = infer(f, default())
