rename(env, ex) = IRTools.prewalk(x -> x isa Variable ? env[x] : x, ex)

function abstract_group(cfg, i)
  j = IRTools.idoms(cfg', entry = length(cfg))[i]
  group = Int[]
  group!(b) =
    (b == j || b in group) || (push!(group, b); foreach(group!, cfg[b]))
  foreach(group!, cfg[i])
  return sort!(group), j
end

function openbranches(out, env, bl)
  brs = []
  for br in branches(bl)
    br.condition == nothing && (push!(brs, br); break)
    cond = exprtype(out, env[br.condition])
    cond == Const(true) && continue
    cond == Const(false) && (push!(brs, br); break)
    push!(brs, br)
  end
  return brs
end

function traceblock!(out, env, bl)
  for (k, v) in bl
    ex = v.expr
    if isexpr(ex, :call)
      Ts = map(v -> exprtype(out, get(env, v, v)), ex.args)
      if applicable(partial, Ts...)
        T = partial(Ts...)
        env[k] = push!(out, stmt(rename(env, v.expr), type = T))
      else
        error("Call not yet implemented")
      end
    end
  end
end

function trace!(out, ir, args)
  env = Dict()
  foreach((a, b) -> env[a] = b, arguments(ir), args)
  bl = 1
  while true
    traceblock!(out, env, block(ir, bl))
    brs = openbranches(out, env, block(ir, bl))
    if length(brs) == 1
      isreturn(brs[1]) && return env[returnvalue(brs[1])]
      bl = brs[1].block
      foreach((a, b) -> env[a] = get(env, b, 1), arguments(block(ir, bl)), arguments(brs[1]))
    else
      error("abstraction not implemented")
    end
  end
end

function trace(Ts...)
  ir = prepare_ir!(IR(widen.(Ts)...))
  tr = IR()
  args = [argument!(tr, T) for T in Ts]
  return!(tr, trace!(tr, ir, args))
  return tr
end
