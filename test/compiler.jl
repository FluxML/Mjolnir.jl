using Poirot, IRTools, Test
using Poirot.Abstract: @trace

thunk = () -> begin
  x = rand(Uniform(0, 10))
  x^2 > 50
end

ir = @trace thunk()

lpdf = IRTools.func(Poirot.logprob(ir)[1])

@test lpdf(nothing, (7.0,)) == (false, logpdf(Uniform(0, 10), 7.0))
@test lpdf(nothing, (7.5,)) == (true, logpdf(Uniform(0, 10), 7.5))
