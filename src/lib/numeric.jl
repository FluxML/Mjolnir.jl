struct Numeric end

# scalar ops

@pure Numeric !, !=, &, *, +, -, /, \, <, <=, >, >=, ^, |, abs, abs2, acos, acosd,
              acosh, acot, acotd, acoth, acsc, acscd, acsch, asec, asecd, asech,
              asin, asind, asinh, atan, atand, atanh, cbrt, conj, cos, cosd, cosh,
              cospi, cot, cotd, coth, csc, cscd, csch, deg2rad, exp, exp10, exp2,
              expm1, float, inv, log, log10, log1p, log2, rad2deg, sec, secd, sech,
              sin, sind, sinh, sinpi, sqrt, tan, tand, tanh, transpose, trailing_zeros, >>, <<, unsigned, rem, //

@abstract Numeric rand() = Float64
@abstract Numeric randn() = Float64
@abstract Numeric rand(::Type{Bool}) where T = Bool

@abstract Numeric sum(xs::Array{T,N}; dims = :) where {T,N} =
  dims == Const(:) ? T : Array{T,N}

