exprtype(ir, x) = IRTools.exprtype(ir, x, typeof = Const)

xlaop(args, ::AType{typeof(+)}, _, _) =
  Expr(:call, XLATools.Add(), args[2:end]...)

function xlaops!(ir)
  for (v, st) in ir
    ir[v] = xlaop(st.expr.args, exprtype.((ir,), st.expr.args)...)
  end
  return ir
end

xla_layout(x::Type{<:XScalar}) = x
xla_layout(x::Const) = ()

function convert_xla!(ir)
  xlaops!(ir)
  for i = 1:length(arguments(ir))
    argtypes(ir)[i] = xla_layout(argtypes(ir)[i])
  end
  for (v, st) in ir
    ir[v] = stmt(st, type = Any)
  end
  return ir
end
