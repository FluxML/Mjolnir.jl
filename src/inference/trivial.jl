using .Abstract: trace, returntype

struct Trivial end

function infer(f, ::Trivial, tr)
  r = returntype(tr)
  r isa Abstract.Const && return Singleton(r.value)
  return
end
