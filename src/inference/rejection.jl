using ProgressMeter

struct Rejection
  samples::Int
end

Rejection() = Rejection(1000)

function exec(f)
  try
    return f()
  catch e
    e isa ConditionError || rethrow(e)
    return e
  end
end

function infer(f, alg::Rejection, tr = nothing)
  @info "Using rejection sampling, N=$(alg.samples)"
  samples = Core.Compiler.return_type(f, Tuple{})[]
  @showprogress for i = 1:alg.samples
    while (x = exec(f)) isa ConditionError end
    push!(samples, x)
  end
  return Empirical(samples)
end
