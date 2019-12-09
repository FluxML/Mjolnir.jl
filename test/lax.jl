using Poirot.LAX, Test

double(x) = xla(() -> x+x)

@test double(21) == 42
@test double(4.5) == 9.0

let x = 2, y = 2.0
  @test_broken xla(() -> x+y) == 4.0
end

add(a, b) = a+b
@test @code_xla(add(2, 3)) isa Poirot.Abstract.IR

@test xla(() -> 2+2) == 4

let x = 5
  @test xla(() -> 3x^(1+1) + (2x + 1)) == 86
end

relu(x) = xla(() -> x > 0 ? x : 0)

@test relu(5) == 5
@test relu(-5) == 0
@test_broken relu(5.0) == 5.0
