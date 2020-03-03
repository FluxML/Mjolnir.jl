# TODO: `pure` functions should probably have type signatures, to avoid being
# over-general. For now this makes things convenient.

function purem(P, f)
  quote
    Mjolnir.abstract(::$(esc(P)), ::AType{typeof($(esc(f)))}, args::Const...) =
      Const($(esc(f))(map(arg -> arg.value, args)...))
    Mjolnir.abstract(::$(esc(P)), ::AType{typeof($(esc(f)))}, args...) =
      Core.Compiler.return_type($(esc(f)), Tuple{widen.(args)...})
  end
end

macro pure(P, fs)
  if isexpr(fs, :tuple)
    Expr(:block, [purem(P, f) for f in fs.args]...)
  else
    purem(P, fs)
  end
end
