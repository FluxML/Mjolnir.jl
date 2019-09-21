using IRTools
using IRTools: IR, Variable, block, blocks, arguments, argtypes, isexpr, stmt

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

mutable struct Frame
  ir::IR
  stmts::Vector{Vector{Variable}}
  rettype::AType
end

Frame(ir::IR) = Frame(ir, keys.(blocks(ir)), Union{})

function frame(ir::IR, args...)
  prepare_ir!(ir)
  argtypes(ir) .= args
  return Frame(ir)
end

struct Inference
  frames::Set{Frame}
  queue::WorkQueue{Any}
end

exprtype(ir, x) = IRTools.exprtype(ir, x)
exprtype(ir, x::GlobalRef) = Const(getproperty(x.mod, x.name))

function infercall!(inf, fr, ex)
  partial(exprtype.((fr.ir,), ex.args)...)
end

function step!(inf::Inference)
  frame, block, ip = pop!(inf.queue)
  if ip <= length(frame.stmts[block])
    var = frame.stmts[block][ip]
    st = frame.ir[var]
    if isexpr(st.expr, :call)
      T = infercall!(inf, frame, st.expr)
      frame.ir[var] = stmt(frame.ir[var], type = _union(st.type, T))
    end
    push!(inf.queue, (frame, block, ip+1))
  else
    block = IRTools.block(frame.ir, block)
    if IRTools.isreturn(block)
      T = exprtype(frame.ir, IRTools.returnvalue(block))
      T == frame.rettype && return
      frame.rettype = _union(frame.rettype, T)
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
  Inference(Set([fr]), q)
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
