module LAX

using XLATools, MacroTools, IRTools, IRTools.All
using XLATools: XArray, XScalar, Shape
using ..Abstract: AType, Const, trace

export @code_xla, xla

include("convert.jl")
include("rt.jl")

macro code_xla(ex)
  @capture(ex, f_(args__)) || error("@trace f(args...)")
  quote
    tr = trace(Const($(esc(f))), typeof.(($(esc.(args)...),))...)
    convert_xla!(tr, ($(esc(f)), $(esc.(args)...)))
  end
end

end
