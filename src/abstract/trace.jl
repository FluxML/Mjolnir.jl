rename(env, ex) = IRTools.prewalk(x -> x isa Variable ? env[x] : x, ex)

function inline_consts!(ir::IR)
  env = Dict()
  for (v, st) in ir
    if st.type isa Const
      delete!(ir, v)
      env[v] = st.type.value
    else
      env[v] = v
    end
  end
  return IRTools.prewalk!(x -> get(env, x, x), ir)
end

cleanup!(ir) = ir |> inline_consts! |> IRTools.prune! |> IRTools.renumber

function copyblock!(ir::IR, b)
  c = IRTools.block!(ir)
  env = Dict()
  for (arg, T) in zip(arguments(b), argtypes(b))
    env[arg] = argument!(c, nothing, T, insert = false)
  end
  for (v, st) in b
    env[v] = push!(c, rename(env, st))
  end
  for br in IRTools.branches(b)
    push!(branches(c), rename(env, br))
  end
  return c
end

function abstract_group(cfg, i)
  j = IRTools.idoms(cfg', entry = length(cfg))[i]
  group = Int[]
  group!(b) =
    (b == j || b in group) || (push!(group, b); foreach(group!, cfg[b]))
  foreach(group!, cfg[i])
  return sort!(group), j
end

function extract_group(bl)
  out = IR()
  args = union(arguments.(branches(block(bl.ir, bl.id)))...)
  args = union(args, filter(x -> x != nothing, map(x -> x.condition, branches(block(bl.ir, bl.id)))))
  innerargs = Dict(a => argument!(out, Union{}) for a in args)
  for br in branches(block(bl.ir, bl.id))
    push!(branches(block(out, 1)), rename(innerargs, br))
  end
  bs, after = abstract_group(CFG(bl.ir), bl.id)
  bmap = Dict()
  for b in bs
    bmap[b] = copyblock!(out, block(bl.ir, b)).id
  end
  ret = IRTools.block!(out)
  bmap[after] = ret.id
  for (arg, T) in zip(arguments(block(bl.ir, after)), argtypes(block(bl.ir, after)))
    argument!(ret, nothing, T, insert = false)
  end
  for b in blocks(out), (i, br) in enumerate(branches(b))
    branches(b)[i] = IRTools.Branch(br, block = bmap[br.block])
  end
  IRTools.domorder!(out)
  return out, args, after
end

function inline!(out, ir, args)
  env = Dict(zip(arguments(ir), args))
  before = blocks(out)[end]
  for br in branches(block(ir, 1))
    push!(branches(before), rename(env, br))
  end
  bmap = Dict()
  for bl in blocks(ir)[2:end]
    bmap[bl.id] = copyblock!(out, bl).id
  end
  for b in before.id:blocks(out)[end].id, (i, br) in enumerate(branches(block(ir, b)))
    branches(block(ir, b))[i] = IRTools.Branch(br, block = bmap[br.block])
  end
end

function abstract!(out, bl, env)
  ir, args, after = extract_group(bl)
  for i = 1:length(args)
    argtypes(ir)[i] = exprtype(out, rename(env, args[i]))
  end
  infer!(Inference(Frame(ir)))
  inline!(out, ir, rename.((env,), args))
  for (k, v) in zip(arguments(block(bl.ir, after)), arguments(blocks(out)[end]))
    env[k] = v
  end
  return after
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

nodetype(x, T::AType) = T
nodetype(x, T::Type) = Node{T}(x)
nodetype(ir::IR, x) = nodetype(x, exprtype(ir, x))

function traceblock!(out, env, bl)
  for (k, v) in bl
    ex = v.expr
    if isexpr(ex, :call)
      Ts = map(v -> nodetype(out, get(env, v, v)), ex.args)
      if (T = partial(Ts...)) != nothing
        if T isa Node
          env[k] = T.value
        else
          env[k] = push!(out, stmt(rename(env, v.expr), type = T))
        end
      else
        env[k] = tracecall!(out, ex.args, Ts)
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
      bl = abstract!(out, block(ir, bl), env)
    end
  end
end

function tracecall!(tr, args, Ts)
  ir = prepare_ir!(IR(widen.(Ts)...))
  trace!(tr, ir, args)
end

function trace(Ts...)
  tr = IR()
  args = [argument!(tr, T) for T in Ts]
  return!(tr, tracecall!(tr, args, Ts))
  return cleanup!(tr)
end

atype(T::AType) = T
atype(x) = Const(x)

macro trace(ex)
  @capture(ex, f_(args__)) || error("@trace f(args...)")
  :(trace(atype.(($(esc(f)), $(esc.(args)...)))...))
end
