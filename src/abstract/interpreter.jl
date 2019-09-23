struct Partial{T}
  value
end

struct Const{T}
  value::T
end

const AType{T} = Union{Type{T},Const{T},Partial{T}}

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

mutable struct Frame
  ir::IR
  edges::Vector{Any}
  stmts::Vector{Vector{Variable}}
  rettype::AType
end

Frame(ir::IR) = Frame(ir, [], keys.(blocks(ir)), Union{})

function frame(ir::IR, args...)
  prepare_ir!(ir)
  argtypes(ir) .= args
  return Frame(ir)
end

struct Inference
  frames::Dict{Vector{AType},Frame}
  queue::WorkQueue{Any}
end

exprtype(ir, x::Variable) = IRTools.exprtype(ir, x)
exprtype(ir, x::Union{Number,String}) = Const(x)
exprtype(ir, x::GlobalRef) = Const(getproperty(x.mod, x.name))

function infercall!(inf, loc, ex)
  Ts = exprtype.((loc[1].ir,), ex.args)
  applicable(partial, Ts...) && return partial(Ts...)
  ir = IR(widen.(Ts)...)
  if !haskey(inf.frames, Ts)
    fr = inf.frames[Ts] = frame(IR(widen.(Ts)...), Ts...)
    push!(inf.queue, (fr, 1, 1))
  else
    fr = inf.frames[Ts]
  end
  push!(fr.edges, loc)
  return fr.rettype
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
  frame, block, ip = pop!(inf.queue)
  if ip <= length(frame.stmts[block])
    var = frame.stmts[block][ip]
    st = frame.ir[var]
    if isexpr(st.expr, :call)
      T = infercall!(inf, (frame, block, ip), st.expr)
      if T != Union{}
        frame.ir[var] = stmt(frame.ir[var], type = _union(st.type, T))
        push!(inf.queue, (frame, block, ip+1))
      end
    end
  else
    block = IRTools.block(frame.ir, block)
    for br in openbranches(block)
      if isreturn(br)
        T = exprtype(frame.ir, IRTools.returnvalue(block))
        _issubtype(T, frame.rettype) && return
        frame.rettype = _union(frame.rettype, T)
        foreach(loc -> push!(inf.queue, loc), frame.edges)
      else
        args = exprtype.((frame.ir,), arguments(br))
        if blockargs!(IRTools.block(frame.ir, br.block), args)
          push!(inf.queue, (frame, br.block, 1))
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
  return inf
end

function Inference(fr::Frame)
  q = WorkQueue{Any}()
  push!(q, (fr, 1, 1))
  Inference(Dict(argtypes(fr.ir)=>fr), q)
end

function infer!(ir::IR, args...)
  fr = frame(ir, args...)
  inf = Inference(fr)
  infer!(inf)
end

function return_type(ir::IR, args...)
  fr = frame(ir, args...)
  inf = Inference(fr)
  infer!(inf)
  return fr.rettype
end
