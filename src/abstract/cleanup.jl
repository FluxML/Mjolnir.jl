function inline_consts!(ir::IR)
  env = Dict()
  for (v, st) in ir
    if st.type isa Union{Const,Node}
      delete!(ir, v)
      env[v] = st.type.value
    else
      env[v] = v
    end
  end
  return IRTools.prewalk!(x -> get(env, x, x), ir)
end

function partials!(ir::IR)
  slots = IdDict()
  slot(k, T) = Base.@get!(slots, k, Slot(gensym(:partial), T))
  for (v, st) in ir
    ex = st.expr
    if iscall(ex, setindex!)
      exprtype(ir, ex.args[2]) isa Partial{<:Dict} || continue
      key = exprtype(ir, ex.args[2]), exprtype(ir, ex.args[4])::Const
      T = key[1].value[key[2].value]
      insert!(ir, v, Expr(:(=), slot(key, T), ex.args[3]))
    elseif iscall(ex, getindex)
      exprtype(ir, ex.args[2]) isa Partial{<:Dict} || continue
      key = exprtype(ir, ex.args[2]), exprtype(ir, ex.args[3])::Const
      T = key[1].value[key[2].value]
      ir[v] = slot(key, T)
    end
  end
  for (v, st) in ir
    st.type isa Partial{<:Dict} && delete!(ir, v)
  end
  return ir
end

function trimblocks!(ir)
  i = 1
  while i <= length(blocks(ir))
    bl = block(ir, i)
    # assume no implicit branches
    # don't bother with blocks that have args (for now)
    if isempty(bl) && length(branches(bl)) == 1 && isempty(arguments(bl))
      for a in predecessors(bl), i in 1:length(branches(a))
        br = branches(bl)[1]
        branches(a)[i].block == bl.id || continue
        branches(a)[i] = Branch(branches(a)[i], block = br.block, args = br.args)
      end
      deleteblock!(ir, i)
    else
      i += 1
    end
  end
  return ir
end

cleanup!(ir) =
  ir |> inline_consts! |> partials! |> ssa! |> prune! |> trimblocks! |> renumber
