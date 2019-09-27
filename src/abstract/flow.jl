struct Partial{T}
  value
end

struct Const{T}
  value::T
  Const(x) = new{Core.Typeof(x)}(x)
end

struct Node{T}
  value::Variable
end

const AType{T} = Union{Type{T},Const{T},Partial{T},Node{T}}

Base.show(io::IO, c::Const) = print(io, "const(", c.value, ")")

widen(::AType{T}) where T = T

_union(::Type{Union{}}, T) = T
_union(S, T) = Union{widen(S), widen(T)}
_issubtype(S, T::Type) = widen(S) <: T
_issubtype(S, T) = S == T

function prepare_ir!(ir)
  IRTools.expand!(ir)
  for b in ir.blocks
    b.argtypes .= Union{}
    for i in 1:length(b.stmts)
      b.stmts[i] = stmt(b.stmts[i], type = Union{})
    end
  end
  return ir
end

function blockargs!(b, args)
  changed = false
  for i = 1:length(argtypes(b))
    _issubtype(args[i], argtypes(b)[i]) && continue
    argtypes(b)[i] = _union(argtypes(b)[i], args[i])
    changed = true
  end
  return changed
end

# TODO clean up edges when blocks are reset
mutable struct Frame
  ir::IR
  inlined::Vector{Vector{IR}}
  edges::Vector{Any}
  stmts::Vector{Vector{Variable}}
  rettype::AType
end

getblock(fr::Frame, b, follow) =
  follow == 0 ? (block(fr.ir, b), fr.stmts[b]) :
    (block(fr.inlined[b][follow], 1), keys(fr.inlined[b][follow]))

Frame(ir::IR) = Frame(ir, [IR[] for _ = 1:length(blocks(ir))], [], keys.(blocks(ir)), Union{})

function frame(ir::IR, args...)
  prepare_ir!(ir)
  argtypes(ir) .= args
  return Frame(ir)
end

function inline_bbs!(fr)
  for b in blocks(fr.ir)
    while !isempty(fr.inlined[b.id])
      follow = popfirst!(fr.inlined[b.id])
      @assert length(openbranches(b)) == 1
      args = arguments(openbranches(b)[1])
      env = Dict(zip(arguments(follow), args))
      for (v, st) in follow
        env[v] = push!(b, rename(env, st))
      end
      empty!(branches(b))
      append!(branches(b), rename.((env,), branches(block(follow, 1))))
    end
  end
end

struct Inference
  frames::Dict{Vector{AType},Frame}
  queue::WorkQueue{Any}
end

exprtype(ir, x::Variable) = IRTools.exprtype(ir, x)
exprtype(ir, x::Union{Number,String}) = Const(x)
exprtype(ir, x::GlobalRef) = Const(getproperty(x.mod, x.name))
exprtype(ir, x::QuoteNode) = Const(x.value)

function infercall!(inf, loc, block, ex)
  Ts = exprtype.((block.ir,), ex.args)
  T = abstract(Ts...)
  T == nothing || return T
  ir = IR(widen.(Ts)...)
  if !haskey(inf.frames, Ts)
    fr = inf.frames[Ts] = frame(IR(widen.(Ts)...), Ts...)
    push!(inf.queue, (fr, 1, 0, 1))
  else
    fr = inf.frames[Ts]
  end
  push!(fr.edges, loc)
  return fr.rettype
end

function inferbranch!(inf, fr, block, follow, br)
  ir = IR(IRTools.block(fr.ir, br.block))
  argtypes(ir) .= exprtype.((getblock(fr, block, follow)[1].ir,), arguments(br))
  push!(fr.inlined[block], ir)
  push!(inf.queue, (fr, block, follow+1, 1))
end

function openbranches(bl)
  brs = []
  for br in branches(bl)
    br.condition == nothing && (push!(brs, br); break)
    cond = exprtype(bl.ir, br.condition)
    cond == Const(true) && continue
    cond == Const(false) && (push!(brs, br); break)
    push!(brs, br)
  end
  return brs
end

function step!(inf::Inference)
  frame, b, f, ip = pop!(inf.queue)
  block, stmts = getblock(frame, b, f)
  if ip <= length(stmts)
    var = stmts[ip]
    st = block[var]
    if isexpr(st.expr, :call)
      T = infercall!(inf, (frame, b, f, ip), block, st.expr)
      if T != Union{}
        block.ir[var] = stmt(block[var], type = _union(st.type, T))
        push!(inf.queue, (frame, b, f, ip+1))
      end
    end
  elseif (brs = openbranches(block); length(brs) == 1 && !isreturn(brs[1]))
    inferbranch!(inf, frame, b, f, brs[1])
  else
    for br in brs
      if isreturn(br)
        T = exprtype(block.ir, IRTools.returnvalue(block))
        _issubtype(T, frame.rettype) && return
        frame.rettype = _union(frame.rettype, T)
        foreach(loc -> push!(inf.queue, loc), frame.edges)
      else
        args = exprtype.((block.ir,), arguments(br))
        if blockargs!(IRTools.block(frame.ir, br.block), args)
          empty!(frame.inlined[br.block])
          push!(inf.queue, (frame, br.block, 0, 1))
        end
      end
    end
  end
  return
end

function infer!(inf::Inference)
  while !isempty(inf.queue)
    step!(inf)
  end
  for (_, fr) in inf.frames
    inline_bbs!(fr)
    fr.ir |> IRTools.trimblocks!
  end
  return inf
end

function Inference(fr::Frame)
  q = WorkQueue{Any}()
  push!(q, (fr, 1, 0, 1))
  Inference(Dict(argtypes(fr.ir)=>fr), q)
end

function infer!(ir::IR, args...)
  fr = frame(ir, args...)
  inf = Inference(fr)
  infer!(inf)
end

function return_type(ir::IR, args...)
  fr = frame(copy(ir), args...)
  inf = Inference(fr)
  infer!(inf)
  return fr.rettype
end
