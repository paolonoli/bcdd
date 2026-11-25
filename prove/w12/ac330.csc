CSC T VERSION 0.1
  PURPOSE "p"
  STATE x : Real INITIAL 0.0
  STATE y : Real INITIAL 0.0
  DEFINE vicino(a: Real, b: Real) := ABS(a - b) <= 0.01
  GUARANTEE g1: ALWAYS vicino(a: x, b: y)
  GUARANTEE g2: ALWAYS vicino(a: x)
  GUARANTEE g3: ALWAYS vicino(c: x, b: y)
END
