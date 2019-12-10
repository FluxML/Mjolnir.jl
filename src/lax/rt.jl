typekey(x::XScalar) = typeof(x)
typekey(x::Array) = (typeof(x), size(x)...)
typekey(x) = (typeof(x), map(f -> typekey(getfield(x, f)), fieldnames(typeof(x)))...)

toxla(x::XScalar) = x
toxla(x::Array{<:XScalar}) = x
toxla(x) = map(f -> toxla(getfield(x, f)), fieldnames(typeof(x)))

const cache = IdDict()

function xla(f)
  key = typekey(f)
  if haskey(cache, key)
    xla_f = cache[key]
  else
    ir = trace(typeof(f))
    ir = convert_xla!(ir, (f,))
    xla_f = cache[key] = XLATools.compile(ir)
  end
  return xla_f(toxla(f))
end
