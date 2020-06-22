@enum BFInstruction inc dec left right accept output debug

struct Loop
  body::Vector{Union{Loop,BFInstruction}}
end

function parsechar(s, i)
  ch = s[i]
  ch == '+' ? (i+1, inc) :
  ch == '-' ? (i+1, dec) :
  ch == '>' ? (i+1, right) :
  ch == '<' ? (i+1, left) :
  ch == '.' ? (i+1, output) :
  ch == ',' ? (i+1, accept) :
  ch == '#' ? (i+1, debug) :
  ch == '[' ? parseloop(s, i) :
  (i+1, nothing)
end

function parseloop(s, i)
  body = Union{Loop,BFInstruction}[]
  i += 1
  while true
    s[i] == ']' && break
    i, op = parsechar(s, i)
    op === nothing || push!(body, op)
  end
  return i+1, Loop(body)
end

function bfparse(s, i = 1)
  is = Union{Loop,BFInstruction}[]
  while i <= length(s)
    i, op = parsechar(s, i)
    op === nothing || push!(is, op)
  end
  return is
end

function debugtape(tape, ptr)
  for i = 1:length(tape)
    print(tape[i])
    i == ptr && print(*)
    print(" ")
  end
  println()
end

function interploop(tape, loop, ptr)
  while tape[ptr] != 0
    ptr = interp(tape, loop.body, ptr)
  end
  return ptr
end

function interp(tape, ops, ptr)
  for op in ops
    if op === inc
      tape[ptr] += 1
    elseif op === dec
      tape[ptr] -= 1
    elseif op === left
      ptr -= 1
    elseif op === right
      ptr += 1
    elseif op === debug
      debugtape(tape, ptr)
    elseif op isa Loop
      ptr = interploop(tape, op, ptr)
    end
  end
  return ptr
end

function interpret(ops, tape = zeros(UInt32, 2^16))
  interp(tape, ops, 1)
  return tape
end

interpret(ops::String, args...) = interpret(bfparse(ops, 1), args...)

mutable struct NVector{T,S} <: AbstractVector{T}
  data::NTuple{S,T}
end

Base.size(xs::NVector) = (length(xs.data),)
Base.getindex(xs::NVector, i::Integer) = xs.data[i]
Base.setindex!(xs::NVector, v, i::Integer)  =
  xs.data = ntuple(j -> j == i ? v : xs.data[j], length(xs.data))
