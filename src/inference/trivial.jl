using .Abstract: trace, returntype
using IRTools: Variable, returnvalue, blocks, isexpr
using IRTools.Inner: iscall

struct Trivial end

function infer(f, ::Trivial, tr = trace(typeof(f)))
  r = returntype(tr)
  r isa Abstract.Const && return Singleton(r.value)
  any(((v, st),) -> iscall(st.expr, observe), tr) && return
  r = returnvalue(blocks(tr)[end])
  r isa Variable || return
  ex = tr[r].expr
  iscall(ex, rand) && ex.args[2] isa Distribution && return ex.args[2]
  return
end
