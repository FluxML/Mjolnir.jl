struct Singleton{T}
  value::T
end

Base.show(io::IO, x::Singleton) = print(io, "Singleton(", x.value, ")")

# TODO make this a distribution, approximate logpdf etc

struct Empirical{T}
  samples::Vector{T}
end

@forward Empirical.samples Statistics.mean, Statistics.var, Statistics.std, Base.length

rounded(x) = @sprintf("%.2g", x)

function Base.show(io::IO, d::Empirical{Bool})
  print(io, "Empirical Bernoulli(p=$(rounded(mean(d)))), N=$(length(d))")
end

function Base.show(io::IO, d::Empirical{<:Real})
  print(io, "Empirical(mean = $(rounded(mean(d))), std = $(rounded(std(d))), N=$(length(d)))")
end
