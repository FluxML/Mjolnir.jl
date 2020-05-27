mutable struct Trace
  ir::IR
  stack::Vector{Any}
  primitives
  nodes::IdDict{Union{Partial,Shape},Variable}
  ircache::Dict{Any,Any}
  total::Int
end

Trace(P) = Trace(IR(), [], P, IdDict(), Dict(), 0)

function getir(tr::Trace, Ts...)
  Ts = widen.(Ts)
  m = IRTools.meta(Tuple{Ts...})
  m == nothing && return
  key = Base.isgenerated(m.method) ? Ts : (m.method, m.sparams)
  ir = get!(() -> IR(m, prune = false), tr.ircache, key)
  return deepcopy(ir)
end

function node!(tr::Trace, T::Union{Partial,Shape}, v)
  tr.nodes[T] = v
  return
end

struct TraceError
  error
  stack
end

function Base.showerror(io::IO, e::TraceError)
  print(io, "Tracing Error: ")
  showerror(io, e.error)
  for Ts in e.stack
    print(io, "\nin ", Tuple{widen.(Ts)...})
  end
end

rename(env, ex) = IRTools.prewalk(
  x -> x isa GlobalRef ? getfield(x.mod, x.name) :
       x isa Variable ? env[x] : x, ex)

returntype(ir) = exprtype(ir, returnvalue(IRTools.blocks(ir)[end]))

function unapply!(tr, Ts, args)
  if VERSION > v"1.4-" && Ts[1] isa AType{typeof(Core._apply_iterate)}
    Ts = [Const(Core._apply), Ts[3:end]...]
    args = [Core._apply, args[3:end]...]
  end
  Ts[1] isa AType{typeof(Core._apply)} || return Ts, args
  Ts′ = Any[Ts[2]]
  args′ = Any[args[2]]
  for (x, T) in zip(args[3:end], Ts[3:end])
    len = partial(tr.primitives, Const(length), T).value
    for i = 1:len
      t = partial(tr.primitives, Const(getindex), T, Const(i))
      @assert t != nothing
      push!(Ts′, t)
      ex = haskey(tr.nodes, t) ? tr.nodes[t] :
            push!(tr.ir, stmt(xcall(getindex, x, i), type = t))
      push!(args′, ex)
    end
  end
  return unapply!(tr, Ts′, args′)
end

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
  j = IRTools.Inner.idoms(cfg', entry = length(cfg))[i]
  group = Int[]
  group!(b) =
    (b == j || b in group) || (push!(group, b); foreach(group!, cfg[b]))
  foreach(group!, cfg[i])
  return sort!(group), j
end

function extract_group(bl)
  out = IR()
  args = filter(x -> x isa Variable, union(arguments.(branches(block(bl.ir, bl.id)))...))
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
  for b in before.id:blocks(out)[end].id, (i, br) in enumerate(branches(block(out, b)))
    branches(block(out, b))[i] = IRTools.Branch(br, block = bmap[br.block])
  end
end

function abstract!(tr, bl, env)
  ir, args, after = extract_group(bl)
  for i = 1:length(args)
    argtypes(ir)[i] = exprtype(tr.ir, rename(env, args[i]))
  end
  infer!(Inference(Frame(ir), tr.primitives))
  inline!(tr.ir, ir, rename.((env,), args))
  for (k, v) in zip(arguments(block(bl.ir, after)), arguments(blocks(tr.ir)[end]))
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

_nodetype(x, T::AType) = T
_nodetype(x, T::Type) = Node{T}(x)
nodetype(ir::IR, x) = _nodetype(x, exprtype(ir, x))

function replacement(P, args, Ts)
  r = instead(P, args, Ts...)
  r === nothing && return (args, Ts)
  return r
end

function traceblock!(tr::Trace, env, bl)
  for (k, v) in bl
    ex = v.expr
    if isexpr(ex, :call)
      Ts = map(v -> nodetype(tr.ir, rename(env, v)), ex.args)
      Ts, args = unapply!(tr, Ts, rename(env, ex).args)
      Ts[1] === Const(Base.not_int) && (Ts[1] = Const(!))
      args, Ts = replacement(tr.primitives, args, Ts)
      if (T = partial(tr.primitives, Ts...)) != nothing
        tr.total += 1
        if T isa Node && !effectful(Ts...)
          env[k] = T.value
        elseif haskey(tr.nodes, T) && !effectful(Ts...)
          env[k] = tr.nodes[T]
        else
          env[k] = push!(tr.ir, stmt(Expr(:call, args...), type = T))
          T isa Union{Partial,Shape} && (tr.nodes[T] = env[k])
        end
      elseif length(Ts) == 2 && Ts[1] isa Const{<:Type{<:NamedTuple}} && Ts[2] isa Const
        env[k] = Ts[1].value(Ts[2].value)
      else
        env[k] = tracecall!(tr, args, Ts...)
      end
    elseif isexpr(ex, :meta)
    elseif isexpr(ex, :boundscheck, :inbounds)
      env[k] = true
    elseif isexpr(ex)
      error("Can't trace through $(ex.head) expression")
    else
      env[k] = rename(env, ex)
    end
  end
end

function trace!(tr::Trace, ir, args)
  if ir.meta.method.isva
    nargs = ir.meta.method.nargs
    splat = args[nargs:end]
    splat = push!(tr.ir, stmt(xcall(tuple, splat...),
                            type = ptuple(nodetype.((tr.ir,), splat)...)))
    args = [args[1:nargs-1]..., splat]
  end
  env = Dict{Any,Any}(zip(arguments(ir), args))
  bl = 1
  while true
    traceblock!(tr, env, block(ir, bl))
    brs = openbranches(tr.ir, env, block(ir, bl))
    if length(brs) == 1
      isreturn(brs[1]) && return rename(env, returnvalue(brs[1]))
      bl = brs[1].block
      foreach((a, b) -> env[a] = rename(env, b), arguments(block(ir, bl)), arguments(brs[1]))
    else
      bl = abstract!(tr, block(ir, bl), env)
    end
  end
end

function tracecall!(tr::Trace, args, Ts...)
  tr.total += 1
  push!(tr.stack, Ts)
  ir = getir(tr, Ts...)
  ir == nothing && error("No IR for $(Tuple{widen.(Ts)...})")
  ir = ir |> merge_returns! |> prepare_ir!
  result = trace!(tr, ir, args)
  pop!(tr.stack)
  return result
end

"""
    trace(P, Ts...)

Trace the method signature `Ts` using the primtive set `P`. e.g.

    julia> trace(Defaults(), typeof(+), Int, Int)
    1: (%1 :: typeof(+), %2 :: Int64, %3 :: Int64)
      %4 = (%1)(%2, %3) :: Int64
      return %4

    julia> trace(Defaults(), typeof(+), Const(2), Const(2))
    1: (%1 :: typeof(+), %2 :: const(2), %3 :: const(2))
      return 4
"""
function trace(P, Ts...)
  tr = Trace(P)
  try
    argnames = [argument!(tr.ir, T) for T in Ts]
    for (T, x) in zip(Ts, argnames)
      T isa Union{Partial,Shape} && node!(tr, T, x)
    end
    args = [T isa Const ? T.value : arg for (T, arg) in zip(Ts, argnames)]
    args, Ts = replacement(P, args, Ts)
    if (T = partial(tr.primitives, Ts...)) != nothing
      tr.total += 1
      return!(tr.ir, push!(tr.ir, stmt(Expr(:call, args...), type = T)))
    else
      return!(tr.ir, tracecall!(tr, args, Ts...))
    end
    # @info "$(tr.total) functions traced."
    return cleanup!(tr.ir)
  catch e
    throw(TraceError(e, tr.stack))
  end
end

atype(T::AType) = T
atype(x) = Const(x)

function tracem(P, ex)
  @capture(ex, f_(args__)) || error("@trace f(args...)")
  :(trace($(esc(P)), atype.(($(esc(f)), $(esc.(args)...)))...))
end

"""
    @trace f(args...)
    @trace P f(args...)

Get a typed trace for `f`, analagous to `@code_typed`. Note that unlike
`@code_typed`, you probably want to pass types rather than values, e.g.

    julia> @trace Int+Int
    1: (%1 :: const(+), %2 :: Int64, %3 :: Int64)
      %4 = (+)(%2, %3) :: Int64
      return %4

If you instead pass actual integers, Mjolnir will aggressively
constant-propagate them, resulting in a trivial trace.

    julia> @trace 2+2
    1: (%1 :: const(+), %2 :: const(2), %3 :: const(2))
      return 4

`P` is the primitive set used, which is `Mjolnir.Defaults()` by default.
"""
macro trace(P, ex)
  tracem(P, ex)
end

macro trace(ex)
  tracem(Defaults(), ex)
end
