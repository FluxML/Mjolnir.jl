function simplify!(ir)
  for (v, st) in ir
    ex = st.expr
    if iscall(ex, randn) && length(ex.args) == 1
      ir[v] = xcall(rand, Normal(0, 1))
    elseif iscall(ex, rand) && length(ex.args) == 1
      ir[v] = xcall(rand, Uniform(0, 1))
    elseif iscall(ex, rand) && length(ex.args) == 2 && ex.args[2] == Bool
      ir[v] = xcall(rand, Bernoulli(1//2))
    end
  end
  return ir
end

trace(Ts...) = simplify!(Abstract.trace(Ts...))
