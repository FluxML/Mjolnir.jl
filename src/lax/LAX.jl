module LAX

using XLATools, MacroTools
using ..Abstract: Const, trace

export @code_xla

macro code_xla(ex)
  @capture(ex, f_(args__)) || error("@trace f(args...)")
  :(trace(Const($(esc(f))),
          $(map(x -> x isa Symbol ? :(typeof($(esc(x)))) : :(Const($(esc(x)))), args)...)))
end

end
