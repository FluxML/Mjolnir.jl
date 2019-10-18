using IRTools.Inner: Slot

function logprob!(ir)
  vars = []
  vartuple = argument!(ir)
  target = Slot(:target)
  pushfirst!(ir, :($target = 0.0))
  for (v, st) in ir
    if iscall(st.expr, rand)
      T = exprtype(ir, v)
      ir[v] = Expr(:call, getindex, vartuple, length(vars)+1)
      prob = insertafter!(ir, v, Expr(:call, logpdf, st.expr.args[2], v))
      target′ = insertafter!(ir, prob, Expr(:call, +, target, prob))
      insertafter!(ir, target′, :($target = $target′))
      push!(vars, (v, T))
    elseif iscall(st.expr, observe)
      prob = insert!(ir, v, Expr(:call, ifelse, st.expr.args[2], 0.0, -Inf))
      target′ = insert!(ir, v, Expr(:call, +, target, prob))
      insert!(ir, v, :($target = $target′))
      delete!(ir, v)
    end
  end
  return!(ir, push!(ir, Expr(:call, tuple, returnvalue(blocks(ir)[end]), target)))
  ssa!(ir)
  return ir, vars
end

logprob(ir) = logprob!(copy(ir))
