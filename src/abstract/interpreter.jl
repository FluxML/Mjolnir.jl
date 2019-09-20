using IRTools
using IRTools: IR, Variable, block, blocks, arguments, isexpr

struct Partial{T}
  value
end

struct Const{T}
  value::T
end

const AType{T} = Union{Type{T},Const{T},Partial{T}}

mutable struct Interpreter
  ir::IR
  ip::Base.Tuple{Int,Int}
  env::Dict{Variable,Any}
  stmts::Vector{Vector{Variable}}
end

function interpreter(ir, args...)
  env = Dict(zip(arguments(block(ir, 1)), args))
  Interpreter(ir, (1, 1), env, keys.(blocks(ir)))
end

lookup(it, v::Union{Number,String}) = Const(v)
lookup(it, v::GlobalRef) = Const(getproperty(v.mod, v.name))
lookup(it, v::Variable) = it.env[v]

unwrapbool(c::Const{Bool}) = c.value
unwrapbool(c) = error("Value-dependent control flow not supported (yet).")

function step!(it::Interpreter)
  b, st = it.ip
  if st > length(it.stmts[b])
    for br in IRTools.branches(block(it.ir, b))
      IRTools.isconditional(br) && unwrapbool(it.env[br.condition]) && continue
      IRTools.isreturn(br) && return lookup(it, br.args[1])
      it.ip = br.block, 1
      for (arg, x) in zip(arguments(block(it.ir, br.block)), br.args)
        it.env[arg] = lookup(it, x)
      end
      return
    end
    it.ip = b+1, 1
    return
  else
    v = it.stmts[b][st]
    ex = it.ir[v].expr
    it.env[v] = eval_stmt(it, ex)
    it.ip = b, st+1
    return
  end
end

function eval_stmt(it::Interpreter, ex)
  if isexpr(ex, :call)
    args = map(x -> lookup(it, x), ex.args)
    partial(args...)
  else
    error("Unrecognised expression $(ex.head)")
  end
end

function run!(it::Interpreter)
  while (r = step!(it)) == nothing end
  return r
end

return_type(ir::IR, args...) = run!(interpreter(ir, args...))
