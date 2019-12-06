module LAX

using XLATools, MacroTools, IRTools, IRTools.All
using XLATools: XScalar
using ..Abstract: AType, Const, trace

export @code_xla

include("convert.jl")

macro code_xla(ex)
  @capture(ex, f_(args__)) || error("@trace f(args...)")
  quote
    tr = trace(Const($(esc(f))), typeof.(($(args...),))...)
    convert_xla!(tr)
  end
end

end
