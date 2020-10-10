import Base: hash, ==

mutable struct Partial{T}
  value
end

struct Const{T}
  value::T
  Const(x) = new{Core.Typeof(x)}(x)
end

mutable struct Shape{T}
  size::NTuple{N,Int} where N
end

struct Node{T}
  value::Variable
end

for T in :[Partial, Const, Shape, Node].args
  @eval hash(x::$T, h::UInt64) = hash($T, hash(getfield(x, 1), h))
  @eval x::$T == y::$T = getfield(x, 1) == getfield(y, 1)
end

const AType{T} = Union{Type{T},Const{T},Shape{T},Partial{T},Node{T}}

Base.show(io::IO, c::Const) = print(io, "const(", c.value, ")")

widen(::AType{T}) where T = T
Base.eltype(x::Shape) = eltype(widen(x))
Base.size(x::Shape) = x.size
Base.ndims(x::Shape) = length(x.size)

Base.size(x::Const{<:Array}) = size(x.value)
Base.eltype(x::Const{<:Array}) = eltype(x.value)
Base.ndims(x::Const{<:Array}) = ndims(x.value)
Base.size(::AType{<:Number}) = ()
Base.eltype(T::AType{<:Number}) = widen(T)
Base.ndims(T::AType{<:Number}) = 0

ptuple() = Const(())
ptuple(x::Const...) = Const(map(x -> x.value, x))
ptuple(x::Type...) = Tuple{x...}
ptuple(x...) = Partial{Tuple{widen.(x)...}}((x...,))

_union(::Type{Union{}}, T) = T
_union(S::Const, T::Const) = S == T ? S : Union{widen(S),widen(T)}
_union(S::Partial, T::Partial) = S == T ? S : Union{widen(S),widen(T)}
_union(S, T) = Union{widen(S), widen(T)}
_issubtype(S, T::Type) = widen(S) <: T
_issubtype(S, T) = S == T

function instrument(ex)
  isexpr(ex, :new) ? xcall(Mjolnir, :__new__, ex.args...) :
  isexpr(ex, :splatnew) ? xcall(Mjolnir, :__splatnew__, ex.args...) :
  ex
end

function prepare_ir!(ir)
  ir |> IRTools.expand! |> IRTools.explicitbranch!
  for b in ir.blocks
    b.argtypes .= Union{}
    for i in 1:length(b.stmts)
      st = b.stmts[i]
      b.stmts[i] = stmt(st, expr = instrument(st.expr), type = Union{})
    end
  end
  return ir
end

function blockargs!(b, args)
  isempty(args) && return true # TODO be more fine grained
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

# TODO clear up inlined edges
uninline!(fr::Frame, b, follow) = deleteat!(fr.inlined[b], follow+1:length(fr.inlined[b]))

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
  edges::IdDict{Partial,Any}
  primitives
end

struct MutCtx
  inf::Inference
  ip
end

function edge!(cx::MutCtx, x::Partial) # TODO: clear edges?
  push!(get!(cx.inf.edges, x, Set()), cx.ip)
  return
end

function visit!(cx::MutCtx, x::Partial) # TODO: can do this by key
  if haskey(cx.inf.edges, x)
    push!(cx.inf.queue, cx.inf.edges[x]...)
  end
end

exprtype(ir, x) = IRTools.exprtype(ir, x, typeof = Const)
exprtype(ir, x::GlobalRef) = Const(getproperty(x.mod, x.name))

function infercall!(inf, loc, block, ex)
  Ts = exprtype.((block.ir,), ex.args)
  Ts[1] === Const(Base.not_int) && (Ts[1] = Const(!))
  T = mutate(inf.primitives, MutCtx(inf, loc), Ts...)
  T == nothing || return T
  ir = IR(widen.(Ts)...)
  ir == nothing && error("No IR for $(Tuple{widen.(Ts)...})")
  if !haskey(inf.frames, Ts)
    fr = inf.frames[Ts] = frame(ir, Ts...)
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
    uninline!(frame, b, f)
    if ip <= length(stmts)
        var = stmts[ip]
        st = block[var]
        st.expr isa QuoteNode && return
        if isexpr(st.expr, :call)
            T = infercall!(inf, (frame, b, f, ip), block, st.expr)
            if T != Union{}
                block.ir[var] = stmt(block[var], type = _union(st.type, T))
                push!(inf.queue, (frame, b, f, ip+1))
            end
        elseif isexpr(st.expr, :inbounds)
            push!(inf.queue, (frame, b, f, ip+1))
        else
            error("Unrecognised expression $(st.expr)")
        end
    elseif (brs = openbranches(block); length(brs) == 1 && !isreturn(brs[1])
            && !(brs[1].block == length(frame.ir.blocks)))
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
        fr.ir |> IRTools.Inner.trimblocks!
    end
    return inf
end

function Inference(fr::Frame, P)
    q = WorkQueue{Any}()
    push!(q, (fr, 1, 0, 1))
    Inference(Dict(argtypes(fr.ir)=>fr), q, IdDict(), P)
end

function infer!(P, ir::IR, args...)
    fr = frame(ir, args...)
    inf = Inference(fr, P)
    infer!(inf)
end

function return_type(ir::IR, args...)
    fr = frame(copy(ir), args...)
    inf = Inference(fr, Defaults())
    infer!(inf)
    return fr.rettype
end
