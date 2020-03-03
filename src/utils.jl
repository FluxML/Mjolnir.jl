struct WorkQueue{T}
  items::Vector{T}
end

WorkQueue{T}() where T = WorkQueue(T[])

WorkQueue() = WorkQueue{Any}()

function Base.push!(q::WorkQueue, x)
  i = findfirst(==(x), q.items)
  i === nothing || (deleteat!(q.items, i))
  push!(q.items, x)
  return q
end

function Base.push!(q::WorkQueue, xs...)
  for x in xs
    push!(q, x)
  end
  return q
end

Base.pop!(q::WorkQueue) = pop!(q.items)
Base.isempty(q::WorkQueue) = isempty(q.items)
