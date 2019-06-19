struct ABC{F}
  compare::F
  eta::Float64
end

ABC(compare) = ABC(compare, 0.5)

(J::ABC)(f, args...) = function (obs)

end
