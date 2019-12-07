exprtype(ir, x) = IRTools.exprtype(ir, x, typeof = Const)

layout(x::XScalar) = typeof(x)
layout(x) = map(f -> layout(getfield(x, f)), fieldnames(typeof(x)))

xlaop(args, ::AType{typeof(+)}, _, _) =
  Expr(:call, XLATools.Add(), args[2:end]...)

fieldnum(T, f) = findfirst(==(f), fieldnames(T))

xlaop(args, ::AType{typeof(getfield)}, ::AType{T}, f::Const{Symbol}) where T =
  Expr(:call, XLATools.GetTupleElement(fieldnum(T, f.value)-1), args[2])

function xlaops!(ir)
  for (v, st) in ir
    ir[v] = xlaop(st.expr.args, exprtype.((ir,), st.expr.args)...)
  end
  return ir
end

function convert_xla!(ir, T)
  xlaops!(ir)
  for i = 1:length(arguments(ir))
    argtypes(ir)[i] = layout(T[i])
  end
  for (v, st) in ir
    ir[v] = stmt(st, type = Any)
  end
  return ir
end
