using Poirot.LAX, Test

function double(x)
  xla() do
    x+x
  end
end

@test double(21) == 42

add(a, b) = a+b
@test @code_xla(add(2, 3)) isa Poirot.Abstract.IR
