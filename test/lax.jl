using Poirot.LAX, Test

function double(x)
  xla() do
    x+x
  end
end

@test double(21) == 42
