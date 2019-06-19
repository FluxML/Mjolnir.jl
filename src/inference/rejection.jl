struct Rejection{F}
  equal::F
end

Rejection() = Rejection(==)

(J::Rejection)(f, args...) = function (obs; samples = 1_000)
  values = map(x -> eltype(x)[], args)
  while length(values[1]) < samples
    xs = map(rand, args)
    if J.equal(f(xs...), obs)
      foreach(push!, values, xs)
    end
  end
  return map(Sample, values)
end
